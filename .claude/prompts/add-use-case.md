# Add New Use Case

Use this prompt to add a new use case to an existing bounded context.

## Prompt Template
```
Add a new use case to the {{CONTEXT}} context:

Use Case: {{USE_CASE_NAME}}
Description: {{DESCRIPTION}}

Requirements:
1. Create {{UseCase}}Command/Query class
2. Create {{UseCase}}UseCase extending BaseCommand/BaseQuery
3. Implement business logic:
   {{BUSINESS_LOGIC_STEPS}}
4. Add permission checks
5. Handle domain events
6. Add endpoint to {{Controller}}
7. Create request/response DTOs
8. Add Swagger documentation
9. Write unit and integration tests

Follow DDD principles and rules.md
```

## Example
```
Add a new use case to the card context:

Use Case: FavoriteCardUseCase
Description: Allow users to mark cards as favorites

Requirements:
1. Create FavoriteCardCommand class
2. Create FavoriteCardUseCase extending BaseCommand
3. Implement business logic:
   - Load card by ID
   - Check user has permission to favorite
   - Call card.toggleFavorite() method
   - Save card
   - Emit CardFavoritedEvent or CardUnfavoritedEvent
4. Add permission checks for READ permission
5. Handle domain events (update user's favorite list)
6. Add PUT /cards/:id/favorite endpoint to CardController
7. Create FavoriteCardDto (empty) and CardResponseDto
8. Add Swagger documentation
9. Write unit and integration tests

Also update Card aggregate to add:
- isFavorite property
- toggleFavorite() method
- CardFavoritedEvent and CardUnfavoritedEvent

Follow DDD principles and rules.md
```