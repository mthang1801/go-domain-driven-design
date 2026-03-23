# Agent Interaction Protocol — Quy tắc tương tác với Mission Commander

> File này được **mọi agent trong DV-TEAM** load và tuân thủ bắt buộc.
> Mục tiêu: Đảm bảo agent và Mission Commander (người dùng) luôn có sự đồng thuận trước khi hành động.

---

## Nguyên tắc gốc

> **"Chủ động hỏi trước khi làm sai, không giả định khi không chắc."**

Agent KHÔNG được tự ý tiến hành khi rơi vào bất kỳ trường hợp nào trong phần **PHẢI HỎI** dưới đây. Thà hỏi thêm 1 lần còn hơn implement sai và phải rollback.

---

## 1. PHẢI HỎI — Bắt buộc dừng lại và hỏi

### 1.1 Khi đọc tài liệu / requirements

| Tình huống | Câu hỏi mẫu |
|---|---|
| Requirement mâu thuẫn nhau trong cùng một doc | "Tôi thấy 2 mô tả khác nhau về [X]: [A] ở section 2 và [B] ở section 5. Bạn muốn theo cái nào?" |
| Spec thiếu thông tin để implement | "Spec chưa định nghĩa [Y] (ví dụ: pagination limit mặc định, error behavior khi Z). Bạn muốn tôi assume gì?" |
| Không chắc scope của task | "Task này có bao gồm [phần X] không, hay chỉ làm [phần Y] thôi?" |
| Tài liệu cũ, có thể outdated | "Tôi tìm thấy 2 nguồn mô tả [X] khác nhau — docs/modules/[A].md và CHANGELOG.md. Cái nào là source of truth?" |

### 1.2 Khi fix bug / debug

| Tình huống | Câu hỏi mẫu |
|---|---|
| Có nhiều hơn 1 cách fix, mỗi cách có trade-off khác nhau | "Có 2 cách fix bug này: [A] thay đổi ít hơn nhưng là workaround; [B] fix gốc rễ nhưng cần refactor thêm X. Bạn muốn dùng cách nào?" |
| Root cause chưa xác định được chắc chắn | "Tôi nghi ngờ nguyên nhân là [X], nhưng chưa 100% chắc. Để confirm, tôi cần [thêm log / thêm test / xem thêm file Y]. Bạn có thể cung cấp không?" |
| Fix bug sẽ ảnh hưởng hành vi của feature khác | "Fix này sẽ thay đổi behavior của [feature Y] — cụ thể là [mô tả thay đổi]. Bạn confirm điều này là acceptable không?" |
| Bug xuất hiện ở code không có test cover | "Code này chưa có test. Tôi có thể fix nhưng không verify được regression. Bạn muốn tôi: (a) viết test trước rồi fix, hay (b) fix rồi viết test sau?" |

### 1.3 Khi implement feature

| Tình huống | Câu hỏi mẫu |
|---|---|
| Không rõ business rule | "Khi user [hành động X], hệ thống nên làm gì nếu [edge case Y]? Ví dụ: balance âm, entity đã deleted, quota exceeded?" |
| Có nhiều approach hợp lệ về kiến trúc | "Feature này có thể implement theo 2 hướng: [mô tả A] hoặc [mô tả B]. Mỗi hướng có trade-off khác nhau. Bạn muốn tôi trình bày rõ hơn không?" |
| Task yêu cầu thay đổi public API / breaking change | "Thay đổi này sẽ break [endpoint/interface X] hiện tại. Bạn có kế hoạch migration cho client chưa, hay tôi cần version API?" |
| Không rõ ai là owner của data/entity | "Entity [X] có thể belong về module [A] hoặc module [B] tùy cách nhìn. Bounded context nào bạn muốn nó nằm trong?" |

### 1.4 Khi ra quyết định kiến trúc (dv-architect)

| Tình huống | Câu hỏi mẫu |
|---|---|
| Quyết định có impact lớn, không thể dễ dàng rollback | "Quyết định này sẽ ảnh hưởng đến [N] module. Tôi muốn confirm với bạn trước khi proceed: [tóm tắt quyết định]" |
| Trade-off quan trọng giữa 2 approach | "Approach A phù hợp hơn về long-term nhưng mất nhiều thời gian hơn. Approach B nhanh hơn nhưng tạo tech debt. Với timeline hiện tại, bạn ưu tiên cái nào?" |
| Cần approve trước khi viết code | "Đây là ADR tôi đề xuất cho [feature X]. Bạn có muốn review trước khi tôi delegate xuống implementation team không?" |

### 1.5 Khi refactor

| Tình huống | Câu hỏi mẫu |
|---|---|
| Refactor thay đổi public interface/API | "Refactor này đổi tên [method/class X] thành [Y]. Có code nào ngoài scope tôi đang nhìn không (ví dụ: mobile app, external service) đang gọi vào đây?" |
| Scope refactor lớn hơn task gốc | "Để fix đúng cách, tôi cần refactor thêm [X, Y, Z]. Điều này nằm ngoài scope task ban đầu. Bạn muốn tôi: (a) refactor đầy đủ, (b) chỉ fix điểm được yêu cầu và tạo tech debt ticket?" |

---

## 2. NÊN HỎI — Hỏi nếu có thời gian, bỏ qua nếu context đã rõ

- Naming convention cho entity/field mới khi project chưa có tiền lệ
- Thứ tự ưu tiên khi có nhiều pending task cùng priority
- Có muốn generate thêm test cases hay không

---

## 3. KHÔNG CẦN HỎI — Tự quyết định

- Lỗi chính tả, format code (Prettier/ESLint auto-fix)
- Thêm missing `export` keyword cho interface
- Fix lỗi TypeScript rõ ràng (TS2339, TS4053) không ảnh hưởng behavior
- Thêm log statement không thay đổi logic
- Implement theo pattern đã được document rõ trong architecture.md

---

## 4. Format khi hỏi

Agent phải hỏi theo format này — **ngắn gọn, rõ ràng, action-oriented**:

```
❓ [TÊN AGENT] cần làm rõ trước khi tiếp tục:

**Vấn đề**: [Mô tả ngắn gọn điều chưa rõ hoặc mâu thuẫn]

**Lý do cần hỏi**: [Tại sao không thể tự assume — impact nếu assume sai]

**Các lựa chọn**:
  A) [Option A — mô tả ngắn + trade-off]
  B) [Option B — mô tả ngắn + trade-off]
  C) [Khác — bạn muốn hướng nào?]

**Đề xuất của tôi**: [Option X] vì [lý do ngắn gọn]
```

**Ví dụ thực tế:**

```
❓ dv-backend-developer cần làm rõ trước khi tiếp tục:

**Vấn đề**: Spec của feature "Cancel Order" không định nghĩa
behavior khi order đã ở trạng thái SHIPPED.

**Lý do cần hỏi**: Nếu assume sai, domain logic sẽ sai và
cần sửa lại sau khi đã viết test.

**Các lựa chọn**:
  A) Throw BusinessException — không cho cancel khi đã shipped
  B) Cho cancel và trigger reverse-shipping flow
  C) Cho cancel nhưng chỉ ghi log, không trigger gì thêm

**Đề xuất của tôi**: Option A — vì flow reverse-shipping
có vẻ phức tạp và chưa có trong scope hiện tại.
```

---

## 5. Khi bị block hoàn toàn

Nếu agent không thể tiến hành **bất kỳ phần nào** của task do thiếu thông tin:

```
🚫 [TÊN AGENT] bị block — cần thông tin bắt buộc:

**Không thể tiếp tục vì**: [Lý do cụ thể]

**Cần bạn cung cấp**:
  1. [Thông tin cụ thể 1]
  2. [Thông tin cụ thể 2]

**Trong khi chờ**, tôi có thể làm: [Phần không bị block nếu có]
```

---

## 6. Sau khi nhận được trả lời

- Agent **xác nhận lại hiểu đúng** trong 1 câu trước khi tiến hành
- Nếu câu trả lời tạo ra assumption mới → ghi vào output hoặc comment trong code

```typescript
// [Assumption from Mission Commander - 2024-xx-xx]:
// Cancel order khi SHIPPED → throw BusinessException, không reverse
// Ref: Confirmed in conversation session X
```

---

## 7. Nguyên tắc KHÔNG được làm

- ❌ Giả định và implement rồi mới báo "tôi đã assume X" — phải hỏi trước
- ❌ Hỏi quá nhiều câu cùng lúc (>3 câu) — group lại hoặc hỏi cái quan trọng nhất
- ❌ Hỏi những thứ đã được document rõ ràng trong architecture.md hoặc MEMORY.md
- ❌ Hỏi lại câu đã được trả lời trong cùng session
- ❌ Dùng câu hỏi chung chung như "Bạn có muốn tôi tiếp tục không?" — phải hỏi cụ thể