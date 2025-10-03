# Akaunting REST API Documentation

> **Note:** This is the **self-hosted API** documentation. This is separate from the Akaunting.com marketplace API which requires an API key from their cloud service.

## Overview

Akaunting provides a RESTful API for programmatic access to all core accounting features. The API uses JSON for request and response bodies and follows standard HTTP conventions.

**Base URL:** `http://your-domain.com/api`

## Authentication

The API uses **HTTP Basic Authentication**. Any user with the `read-api` permission can access the API using their email and password.

By default, users with the **admin role** have the `read-api` permission.

### Example Authentication

```bash
curl -X GET "http://localhost:8000/api/ping" \
  -u "admin@company.com:123456"
```

### Authentication Headers

```
Authorization: Basic base64(email:password)
```

## Common Request Parameters

### Required Parameters

- `company_id` - Required for most endpoints to specify which company's data to access

### Query Parameters

- `search` - Filter results using search syntax (e.g., `type:customer`, `status:active`)
- `limit` - Number of results per page (pagination)
- `page` - Page number (pagination)
- `sort` - Sort field and direction (e.g., `created_at:desc`)

### Example with Search

```bash
# Get all customer contacts
GET /api/contacts?company_id=1&search=type:customer

# Get all invoices
GET /api/documents?company_id=1&search=type:invoice
```

## Standard Response Format

### Success Response (200 OK)

```json
{
  "data": {
    "id": 1,
    "company_id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    ...
  }
}
```

### Collection Response

```json
{
  "data": [
    {
      "id": 1,
      ...
    },
    {
      "id": 2,
      ...
    }
  ],
  "meta": {
    "current_page": 1,
    "total": 50,
    "per_page": 15
  }
}
```

### Error Response (4xx, 5xx)

```json
{
  "message": "Error description",
  "errors": {
    "field_name": [
      "Validation error message"
    ]
  }
}
```

## API Endpoints

### Ping

Test API connectivity.

```http
GET /api/ping
```

**Response:**

```json
{
  "data": "pong"
}
```

---

### Users

Manage user accounts.

#### List Users

```http
GET /api/users
```

#### Get User

```http
GET /api/users/{id}
```

#### Create User

```http
POST /api/users
```

**Request Body:**

```json
{
  "company_id": 1,
  "email": "user@example.com",
  "name": "John Doe",
  "password": "secure_password",
  "locale": "en-GB",
  "roles": [1],
  "enabled": 1
}
```

#### Update User

```
PUT /api/users/{id}
PATCH /api/users/{id}
```

#### Delete User

```
DELETE /api/users/{id}
```

#### Enable/Disable User

```
GET /api/users/{id}/enable
GET /api/users/{id}/disable
```

---

### Companies

Manage companies (multi-tenancy).

#### List Companies

```http
GET /api/companies
```

#### Get Company

```http
GET /api/companies/{id}
```

#### Create Company

```http
POST /api/companies
```

**Request Body:**

```json
{
  "name": "My Company",
  "email": "company@example.com",
  "tax_number": "123456789",
  "phone": "+1234567890",
  "address": "123 Main St",
  "domain": "mycompany"
}
```

#### Update Company

```http
PUT /api/companies/{id}
PATCH /api/companies/{id}
```

#### Delete Company

```http
DELETE /api/companies/{id}
```

#### Enable/Disable Company

```http
GET /api/companies/{id}/enable
GET /api/companies/{id}/disable
```

#### Check Company Access

```http
GET /api/companies/{id}/owner
```

---

### Contacts

Manage customers and vendors.

#### List Contacts

```http
GET /api/contacts?company_id=1
```

**Filter by type:**

```http
GET /api/contacts?company_id=1&search=type:customer
GET /api/contacts?company_id=1&search=type:vendor
```

#### Get Contact

```http
GET /api/contacts/{id}
GET /api/contacts/{email}  # Can query by email
```

**Response:**

```json
{
  "data": {
    "id": 1,
    "company_id": 1,
    "user_id": null,
    "type": "customer",
    "name": "John Doe",
    "email": "john@example.com",
    "tax_number": "123456789",
    "phone": "+1234567890",
    "address": "123 Main St",
    "website": "https://example.com",
    "currency_code": "USD",
    "enabled": 1,
    "reference": "REF-001",
    "created_from": "web",
    "created_by": 1,
    "created_at": "2025-10-02T12:00:00Z",
    "updated_at": "2025-10-02T12:00:00Z",
    "contact_persons": {
      "data": []
    }
  }
}
```

#### Create Contact

```http
POST /api/contacts
```

**Request Body:**

```json
{
  "company_id": 1,
  "type": "customer",
  "name": "John Doe",
  "email": "john@example.com",
  "tax_number": "123456789",
  "phone": "+1234567890",
  "address": "123 Main St",
  "currency_code": "USD",
  "enabled": 1
}
```

**Required Fields:**
- `type` - "customer" or "vendor"
- `name` - Contact name
- `currency_code` - Valid currency code

**Optional Fields:**
- `email` - Must be unique
- `user_id` - Link to a user account
- `tax_number`
- `phone`
- `address`
- `website`
- `reference` - Custom reference number
- `enabled` - 1 or 0

#### Update Contact
```
PUT /api/contacts/{id}
PATCH /api/contacts/{id}
```

#### Delete Contact
```
DELETE /api/contacts/{id}
```

#### Enable/Disable Contact
```
GET /api/contacts/{id}/enable
GET /api/contacts/{id}/disable
```

---

### Items

Manage products and services.

#### List Items

```
GET /api/items?company_id=1
```

#### Get Item

```
GET /api/items/{id}
```

#### Create Item

```
POST /api/items
```

**Request Body:**

```json
{
  "company_id": 1,
  "type": "product",
  "name": "Product Name",
  "description": "Product description",
  "sale_price": 100.00,
  "purchase_price": 60.00,
  "quantity": 50,
  "tax_ids": [1],
  "category_id": 1,
  "enabled": 1
}
```

**Required Fields:**

- `type` - "product" or "service"
- `name`
- `sale_price`

#### Update Item

```
PUT /api/items/{id}
PATCH /api/items/{id}
```

#### Delete Item
```
DELETE /api/items/{id}
```

#### Enable/Disable Item
```
GET /api/items/{id}/enable
GET /api/items/{id}/disable
```

---

### Documents

Manage invoices and bills (unified document system).

#### List Documents

```
GET /api/documents?company_id=1
```

**Filter by type:**

```
GET /api/documents?company_id=1&search=type:invoice
GET /api/documents?company_id=1&search=type:bill
```

#### Get Document

```
GET /api/documents/{id}
```

#### Create Document

```
POST /api/documents
```

**Request Body (Invoice Example):**

```json
{
  "company_id": 1,
  "type": "invoice",
  "document_number": "INV-2025-001",
  "order_number": "PO-123",
  "status": "draft",
  "issued_at": "2025-10-02 00:00:00",
  "due_at": "2025-11-02 00:00:00",
  "contact_id": 1,
  "contact_name": "John Doe",
  "contact_email": "john@example.com",
  "contact_address": "123 Main St",
  "currency_code": "USD",
  "currency_rate": 1,
  "items": [
    {
      "item_id": 1,
      "name": "Product Name",
      "quantity": 2,
      "price": 100.00,
      "tax_ids": [1],
      "total": 200.00
    }
  ],
  "notes": "Thank you for your business"
}
```

**Required Fields:**

- `type` - "invoice" or "bill"
- `issued_at` - Issue date
- `due_at` - Due date
- `contact_id` - Customer (invoice) or Vendor (bill)
- `currency_code`
- `items` - Array of line items

#### Update Document

```
PUT /api/documents/{id}
PATCH /api/documents/{id}
```

#### Delete Document

```
DELETE /api/documents/{id}
```

#### Mark as Received (Bills)

```
GET /api/documents/{id}/received
```

---

### Document Transactions

Manage payments for invoices/bills.

#### List Transactions for Document

```
GET /api/documents/{document_id}/transactions
```

#### Create Transaction (Payment)

```
POST /api/documents/{document_id}/transactions
```

**Request Body:**

```json
{
  "company_id": 1,
  "type": "income",
  "account_id": 1,
  "paid_at": "2025-10-02 00:00:00",
  "amount": 100.00,
  "currency_code": "USD",
  "currency_rate": 1,
  "description": "Payment received",
  "payment_method": "bank_transfer",
  "reference": "TXN-001"
}
```

---

### Banking - Accounts

Manage bank and cash accounts.

#### List Accounts

```
GET /api/accounts?company_id=1
```

#### Get Account

```
GET /api/accounts/{id}
```

#### Create Account

```
POST /api/accounts
```

**Request Body:**
```json
{
  "company_id": 1,
  "name": "Business Checking",
  "number": "1234567890",
  "currency_code": "USD",
  "opening_balance": 1000.00,
  "bank_name": "Example Bank",
  "bank_phone": "+1234567890",
  "bank_address": "456 Bank St",
  "enabled": 1
}
```

#### Update Account

```
PUT /api/accounts/{id}
PATCH /api/accounts/{id}
```

#### Delete Account

```
DELETE /api/accounts/{id}
```

#### Enable/Disable Account

```
GET /api/accounts/{id}/enable
GET /api/accounts/{id}/disable
```

---

### Banking - Transactions

Manage income and expense transactions.

#### List Transactions

```
GET /api/transactions?company_id=1
```

**Filter by type:**

```
GET /api/transactions?company_id=1&search=type:income
GET /api/transactions?company_id=1&search=type:expense
```

#### Get Transaction

```
GET /api/transactions/{id}
```

#### Create Transaction

```
POST /api/transactions
```

**Request Body:**

```json
{
  "company_id": 1,
  "type": "expense",
  "account_id": 1,
  "paid_at": "2025-10-02 00:00:00",
  "amount": 50.00,
  "currency_code": "USD",
  "currency_rate": 1,
  "description": "Office supplies",
  "category_id": 1,
  "payment_method": "cash",
  "reference": "EXP-001"
}
```

**Required Fields:**

- `type` - "income" or "expense"
- `account_id` - Bank/cash account
- `paid_at` - Transaction date
- `amount`
- `currency_code`
- `category_id`

#### Update Transaction

```
PUT /api/transactions/{id}
PATCH /api/transactions/{id}
```

#### Delete Transaction

```
DELETE /api/transactions/{id}
```

---

### Banking - Transfers

Manage transfers between accounts.

#### List Transfers

```
GET /api/transfers?company_id=1
```

#### Get Transfer

```
GET /api/transfers/{id}
```

#### Create Transfer

```
POST /api/transfers
```

**Request Body:**

```json
{
  "company_id": 1,
  "from_account_id": 1,
  "to_account_id": 2,
  "transferred_at": "2025-10-02 00:00:00",
  "amount": 500.00,
  "description": "Transfer to savings"
}
```

#### Update Transfer

```
PUT /api/transfers/{id}
PATCH /api/transfers/{id}
```

#### Delete Transfer

```
DELETE /api/transfers/{id}
```

---

### Banking - Reconciliations

Manage bank reconciliations.

#### List Reconciliations

```
GET /api/reconciliations?company_id=1
```

#### Get Reconciliation

```
GET /api/reconciliations/{id}
```

#### Create Reconciliation

```
POST /api/reconciliations
```

#### Update Reconciliation

```
PUT /api/reconciliations/{id}
PATCH /api/reconciliations/{id}
```

#### Delete Reconciliation

```
DELETE /api/reconciliations/{id}
```

---

### Categories

Manage income and expense categories.

#### List Categories

```
GET /api/categories?company_id=1
```

**Filter by type:**

```
GET /api/categories?company_id=1&search=type:income
GET /api/categories?company_id=1&search=type:expense
GET /api/categories?company_id=1&search=type:item
GET /api/categories?company_id=1&search=type:other
```

#### Get Category

```
GET /api/categories/{id}
```

#### Create Category

```
POST /api/categories
```

**Request Body:**

```json
{
  "company_id": 1,
  "type": "expense",
  "name": "Office Expenses",
  "color": "#FF0000",
  "enabled": 1
}
```

#### Update Category

```
PUT /api/categories/{id}
PATCH /api/categories/{id}
```

#### Delete Category

```
DELETE /api/categories/{id}
```

#### Enable/Disable Category

```
GET /api/categories/{id}/enable
GET /api/categories/{id}/disable
```

---

### Currencies

Manage multi-currency support.

#### List Currencies

```
GET /api/currencies?company_id=1
```

#### Get Currency

```
GET /api/currencies/{code}
```

#### Create Currency

```
POST /api/currencies
```

**Request Body:**

```json
{
  "company_id": 1,
  "code": "EUR",
  "name": "Euro",
  "rate": 0.85,
  "precision": 2,
  "symbol": "€",
  "symbol_first": 1,
  "decimal_mark": ".",
  "thousands_separator": ",",
  "enabled": 1
}
```

#### Update Currency

```
PUT /api/currencies/{code}
PATCH /api/currencies/{code}
```

#### Delete Currency
```
DELETE /api/currencies/{code}
```

#### Enable/Disable Currency
```
GET /api/currencies/{code}/enable
GET /api/currencies/{code}/disable
```

---

### Taxes

Manage tax rates.

#### List Taxes
```
GET /api/taxes?company_id=1
```

#### Get Tax
```
GET /api/taxes/{id}
```

#### Create Tax
```
POST /api/taxes
```

**Request Body:**
```json
{
  "company_id": 1,
  "name": "VAT",
  "rate": 20.00,
  "type": "inclusive",
  "enabled": 1
}
```

**Tax Types:**
- `normal` - Added to price
- `inclusive` - Included in price
- `compound` - Compound tax
- `fixed` - Fixed amount
- `withholding` - Withholding tax

#### Update Tax
```
PUT /api/taxes/{id}
PATCH /api/taxes/{id}
```

#### Delete Tax
```
DELETE /api/taxes/{id}
```

#### Enable/Disable Tax
```
GET /api/taxes/{id}/enable
GET /api/taxes/{id}/disable
```

---

### Dashboards

Manage dashboard configurations.

#### List Dashboards
```
GET /api/dashboards?company_id=1
```

#### Get Dashboard
```
GET /api/dashboards/{id}
```

#### Create Dashboard
```
POST /api/dashboards
```

#### Update Dashboard
```
PUT /api/dashboards/{id}
PATCH /api/dashboards/{id}
```

#### Delete Dashboard
```
DELETE /api/dashboards/{id}
```

#### Enable/Disable Dashboard
```
GET /api/dashboards/{id}/enable
GET /api/dashboards/{id}/disable
```

---

### Reports

Access financial reports.

#### List Reports
```
GET /api/reports?company_id=1
```

#### Get Report
```
GET /api/reports/{id}?company_id=1
```

---

### Settings

Manage company settings.

#### Get All Settings
```
GET /api/settings?company_id=1
```

#### Get Setting
```
GET /api/settings/{key}?company_id=1
```

#### Update Settings
```
PUT /api/settings
PATCH /api/settings
```

**Request Body:**
```json
{
  "company_id": 1,
  "company.name": "My Company",
  "company.email": "info@company.com",
  "default.currency": "USD",
  "default.locale": "en-GB"
}
```

---

### Translations

Get translation files for localization.

#### Get All Translations for Locale
```
GET /api/translations/{locale}/all
```

Example: `GET /api/translations/en-GB/all`

#### Get Specific Translation File
```
GET /api/translations/{locale}/{file}
```

Example: `GET /api/translations/en-GB/general`

---

## Error Handling

### HTTP Status Codes

- `200 OK` - Successful request
- `201 Created` - Resource created successfully
- `204 No Content` - Successful deletion
- `400 Bad Request` - Invalid request data
- `401 Unauthorized` - Authentication required or failed
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation error
- `500 Internal Server Error` - Server error

### Validation Errors

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": [
      "The email field is required."
    ],
    "amount": [
      "The amount must be a number.",
      "The amount must be greater than 0."
    ]
  }
}
```

---

## Best Practices

### 1. Always Include company_id

Most endpoints require a `company_id` parameter to specify which company's data to access:

```bash
GET /api/contacts?company_id=1
```

### 2. Use Search for Filtering

Use the `search` parameter for filtering instead of multiple query parameters:

```bash
# Good
GET /api/contacts?company_id=1&search=type:customer;enabled:1

# Also works
GET /api/contacts?company_id=1&search=type:customer
```

### 3. Handle Pagination

Large datasets are paginated. Use `page` and `limit` parameters:

```bash
GET /api/contacts?company_id=1&page=2&limit=50
```

### 4. Use Proper Date Formats

Dates should be in `Y-m-d H:i:s` format (e.g., `2025-10-02 14:30:00`).

### 5. Include Timezone Information

Dates are returned in ISO 8601 format with timezone:

```json
"created_at": "2025-10-02T12:00:00Z"
```

### 6. Handle File Uploads

For endpoints that accept file uploads (e.g., company logos, item images), use `multipart/form-data`:

```bash
curl -X POST "http://localhost:8000/api/companies" \
  -u "admin@company.com:password" \
  -F "name=My Company" \
  -F "email=info@company.com" \
  -F "logo=@/path/to/logo.png"
```

---

## Rate Limiting

The API is rate-limited to prevent abuse. Default limits are configured in the Laravel application.

If you exceed the rate limit, you'll receive a `429 Too Many Requests` response.

---

## Postman Collection

To import these endpoints into Postman:

1. Create a new collection
2. Set up environment variables:
   - `base_url`: `http://localhost:8000/api`
   - `email`: Your user email
   - `password`: Your password
   - `company_id`: Your company ID
3. Configure collection-level Basic Auth using `{{email}}` and `{{password}}`

---

## Important Notes

### Self-Hosted vs Cloud API

This documentation covers the **self-hosted REST API** included with Akaunting. This is completely separate from:

- **Akaunting.com Marketplace API** - Requires an API key from akaunting.com
- **App Store features** - Requires cloud account and API key
- **Premium apps** - May require paid subscriptions

The self-hosted API provides full access to all core accounting features without any external dependencies.

### Multi-Tenancy

Akaunting supports multiple companies (multi-tenancy). Always include the `company_id` parameter to specify which company's data you're accessing.

### Permissions

API access is controlled by the `read-api` permission. By default:
- Admin users have this permission
- Regular users need it explicitly granted
- API access respects all user permissions and company associations

---

## Support and Contributions

For bugs or feature requests related to the API:
- GitHub Issues: https://github.com/akaunting/akaunting/issues
- Forum: https://akaunting.com/forum

API source code:
- Routes: `/routes/api.php`
- Controllers: `/app/Http/Controllers/Api/`
- Resources: `/app/Http/Resources/`
- Requests: `/app/Http/Requests/`
