# Timeline

Each `JobApplication` has an ordered thread of `ApplicationEvent` rows. This is in-app only — there is no IMAP, mailbox, or outbound mail.

## Event kinds

```mermaid
flowchart LR
  app[JobApplication]
  created[status_change on create]
  later[status_change on update]
  note[message]
  app --> created
  app --> later
  app --> note
```

| `kind` | When | Fields |
| --- | --- | --- |
| `status_change` | After create, and after `status` changes | `from_status`, `to_status`, optional `dropout_reason`, optional `body` from `status_note` |
| `message` | Candidate posts in the modal | required `body` |

## Dropout

```mermaid
flowchart TB
  status[rejected or withdrawn]
  reason[dropout_reason]
  status --> reason
  reason --> ghosting[ghosting]
  reason --> no_offer[no_offer]
  reason --> withdrew[candidate_withdrew]
  reason --> joke[process_joke]
  reason --> other[other]
```

`dropout_reason` is validated on the application when the **new** status is `rejected` or `withdrawn`. It is copied onto the `status_change` event. Later edits that do not change status do not require it again.

## Authorship

Every event belongs to the signed-in `User`. There is no recruiter reply channel in v1; the thread is the candidate’s log of what happened.

Events are listed chronologically (`created_at`, `id`) in the application modal. `POST /jobseeker/applications/:id/events` adds a `message`.
