## ADDED Requirements

### Requirement: Customer cats are randomly assigned to orders

When OrderSystem generates a new order, it SHALL randomly select a `customer_id` from the pool defined in `CUSTOMER_CAT_TEXTURES` and include it in the order data. The selection SHALL be uniformly random across all 5 customer cats.

#### Scenario: Order generated with random customer assignment

- **WHEN** OrderSystem generates a new order
- **THEN** the order data includes a `customer_id` field from the set `{customer_cat_01, ..., customer_cat_05}`

### Requirement: OrderSlot displays the assigned customer cat

The OrderSlot component's CatIcon SHALL display the customer cat texture corresponding to the `customer_id` assigned to the order. The texture SHALL be resolved via `ResourceDB.get_customer_cat_texture(customer_id)`.

#### Scenario: OrderSlot shows customer cat portrait

- **WHEN** an order with `customer_id = "customer_cat_03"` is displayed in an OrderSlot
- **THEN** the CatIcon TextureRect displays the texture from `CUSTOMER_CAT_TEXTURES["customer_cat_03"]`

#### Scenario: Empty OrderSlot hides cat icon

- **WHEN** an OrderSlot is in empty state (no active order)
- **THEN** the CatIcon is hidden

### Requirement: Customer cat pool is extensible

The `CUSTOMER_CAT_TEXTURES` dictionary SHALL support adding new entries without modifying any query or assignment logic. The `get_all_customer_cat_ids()` method SHALL dynamically return all keys present in the dictionary.

#### Scenario: Adding a 6th customer cat

- **WHEN** a new entry `customer_cat_06` is added to `CUSTOMER_CAT_TEXTURES`
- **THEN** `get_all_customer_cat_ids()` includes it in the returned array, and `get_customer_cat_texture("customer_cat_06")` returns its texture
