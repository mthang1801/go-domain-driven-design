# Import Engine — Full Processing Flow

## 1. Upload & Submit (Presentation → Application)

```text
POST /import/upload (multipart/form-data)
    Controller:
        1. Save file to /tmp/import-{timestamp}-{module}.csv
        2. Create Report record (status=PENDING, correlationId)
        3. importService.submit({ correlationId, module, filePath, fileName, author })
        4. Return { correlationId } → client polls SSE
```

## 2. Queue Processing (BullMQ Worker)

```text
ImportWorker.process(job):
    1. Read job.data: { correlationId, module, filePath, fileName }
    2. processorFactory.create(module) → XxxImportStrategy
    3. reportProgressAdapter.trackingProgress(correlationId, async () => {
            result = await strategy.process(command)
            reportCommandService.updateReport(correlationId, result)
       })
    4. fs.rm(filePath)   ← cleanup temp file
```

## 3. Strategy Pipeline (Application Layer)

```text
XxxImportStrategy.process(command):
    → XxxImportSaga.execute(command)
```

## 4. Saga Execute — Happy Path

```text
CustomerImportSaga.execute(command):
    state = { correlationId, filePath, persistedIds: [], totalRows: 0, ... }

    try {
        runPipeline(state, command):
            worksheet = ImportFactory.createImportCsvWorksheet()
                .setSourceFilePath(filePath)
                .setColumn([...])
            template = ImportFactory.createImportCsvTemplate({ name: module })
            template.addContent(worksheet)

            [pipeline] = pipelineBuilder.buildCsvPipeline(template)
            batched = pipeline.batch(BATCH_SIZE)

            for await (batch of batched.source):
                for (row of batch):
                    state.totalRows++
                    ── Validate format ──────────────────────────
                    if (!EMAIL_REGEXP.test(row.email))  → failedRows++, errors.push, continue
                    if (row.phone && !VN_PHONE.test())  → failedRows++, errors.push, continue
                    ── DB uniqueness ─────────────────────────────
                    if (await repo.existsByEmail(email))→ failedRows++, errors.push, continue
                    if (await repo.existsByPhone(phone))→ failedRows++, errors.push, continue
                    ── Persist ───────────────────────────────────
                    id = await repo.createWithRelations(payload)
                    state.persistedIds.push(id)
                    state.importedRows++
                    await command.onProgress(totalRows, totalRows)

    } catch (err):
        [COMPENSATION — Case 2]

    if (state.failedRows > 0):
        [COMPENSATION — Case 1]

    return { totalRows, importedRows, failedRows, errors }
```

## 5. Compensation Paths

### Case 1 — Soft failures (duplicate, invalid format)

```text
Pipeline completes normally BUT state.failedRows > 0
    → compensate(state):
            if (persistedIds.length > 0)
                repo.deleteByIds(persistedIds)   ← DELETE WHERE id IN (...)
    → return { importedRows: 0, failedRows: totalRows, errors }
```

### Case 2 — Hard failure (unexpected exception)

```text
runPipeline() throws
    → catch(err):
            compensate(state)   ← same deleteByIds
            throw err           ← worker marks job FAILED
```

## 6. Progress Tracking

```text
ImportWorker wraps strategy.process() inside:
    reportProgressAdapter.trackingProgress(correlationId, callback)

Inside callback, strategy calls:
    command.onProgress(processedRows, totalRows)
        → reportProgressAdapter.incrementProcessedCount(correlationId)
        → emit SSE event to frontend

After callback:
    reportCommandService.updateReport(correlationId, {
        totalRecord, processedRecord, errorRecord, errorMessages
    })
```

## 7. All-or-Nothing Guarantee

| Scenario                          | Outcome                                           |
| --------------------------------- | ------------------------------------------------- |
| All rows valid → all persist OK   | ✅ Import SUCCESS, all records kept               |
| Row N fails validation            | ❌ Compensate → delete rows 1..N-1, report FAILED |
| Row N has duplicate DB            | ❌ Compensate → delete rows 1..N-1, report FAILED |
| Unexpected exception mid-pipeline | ❌ Compensate → deleteByIds, re-throw, job FAILED |
| Empty file (0 rows)               | ✅ Import SUCCESS, 0 records                      |
