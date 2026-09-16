# Companies

Shared catalog: one legal row for Google Poland vs Google Ireland, not one row per candidate. Two agencies named “Strategic Staffing” in different countries are two rows.

## Legal identity

```mermaid
flowchart TB
  subgraph identity [Unique when legal_id is set]
    country[country ISO-2]
    kindId[legal_id_kind]
    number[legal_id]
  end
  country --> key[Unique key]
  kindId --> key
  number --> key
  name[official_name]
  short[shortcut]
  name -.-> display[Display only]
  short -.-> display
```

`legal_id_kind`: `nip`, `krs`, `vat`, `ein`, `company_number`, `other`.

Whitespace and hyphens are stripped from `legal_id` before save (`525-234-40-78` → `5252344078`).

New companies from the UI require country + identifier. Legacy tracker strings may be backfilled without a number (partial unique index).

Display:

- `display_name` — shortcut if present, otherwise official name
- `label` — used in selects: `YND · YND Sp. z o.o. · PL`

## Type

| `kind` | Meaning |
| --- | --- |
| `employer` | Direct employer |
| `agency` | Job / recruitment agency |

```mermaid
flowchart LR
  vacancy[Vacancy]
  agency[Agency]
  employer[Employer]
  vacancy -->|recruiter process| agency
  vacancy -->|direct hire| employer
```

The application still points at **one** company: whichever legal entity the candidate is dealing with. A later version can add a second optional `employer_id` if an agency process needs both; v1 does not.

## Catalog UI

```mermaid
flowchart LR
  subgraph jobseeker [Jobseeker]
    list[Index + search]
    card[Show card]
    rate[Upsert own rating]
  end
  subgraph admin [Admin]
    crud[Create / edit / delete]
  end
  list --> card
  card --> rate
  crud --> list
```

Search (`q`, 2+ characters) matches shortcut, official name, and legal id (`ILIKE`).

Jobseeker cannot merge or delete companies. Admin can edit identity fields. Delete is blocked while applications still reference the row (`restrict_with_error`).

## Creating a company from an application

```mermaid
sequenceDiagram
  actor Candidate
  participant Form as Application form
  participant Catalog as Company
  participant App as JobApplication

  alt Existing catalog row
    Candidate->>Form: pick company_id
    Form->>App: save with company_id
  else Not in catalog
    Candidate->>Form: leave company_id blank
    Candidate->>Form: official name + country + legal id
    Form->>Catalog: create Company
    Form->>App: save with new company_id
  end
```

If `company_id` is present, nested `company_attributes` are ignored so an accidental fill of the “new company” fieldset cannot fork a duplicate.
