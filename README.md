# AlfaSoftware — Helpdesk for ASiS ERP

A helpdesk (ticketing) module built on top of ASiS ERP, on SQL Server. It covers
the database structure, the CRUD screens in the web interface, the performance
indicators, the Power BI dashboard, the Vizor report and exposing the data
through a REST API.

Working database: `Student8`.

## File layout

Each file corresponds to one stage of the assignment. The SQL scripts run in
numeric order; the Power BI file is opened once the B5 views exist in the
database.

| File | Contents |
|---|---|
| `SQLAlfaSoftwareA.sql` | SQL exercises against the existing database: SELECT, functions, aggregates, JOINs, subqueries and CTEs, window functions, XML, DDL/CRUD |
| `SQLAlfaSoftwareB1.sql` | Database structure: 6 tables with foreign keys and CHECK constraints |
| `SQLAlfaSoftwareB2.sql` | Test data: lookup tables, tickets, journal, activities |
| `SQLAlfaSoftwareB3.sql` | Trigger that journals state changes |
| `SQLAlfaSoftwareB4.sql` | 19 procedures for the web screens: CRUD, autocomplete, Excel export |
| `SQLAlfaSoftwareB5.sql` | 7 views and one procedure for the indicators |
| `SQLAlfaSoftwareB7.sql` | Vizor report with groupings and subtotals |
| `SQLAlfaSoftwareB9-10.sql` | REST API: GET ticket list, POST create ticket |
| `AlfaSoftware.pbix` | Power BI dashboard over the tables and the indicator views |

## Data model

```
Categorii   ─┐
Prioritati  ─┼─→ Tickete ─┬─→ JurnalTickete     (state history)
StariTicket ─┘            ├─→ ActivitatiTicket  (work reported)
                          └─→ Personal          (requester, assignee)
```

- **Tickete** — the central document. Moves through the flow
  `Nou → Atribuit → In lucru → Rezolvat → Inchis` (new → assigned → in progress
  → resolved → closed)
- **JurnalTickete** — written automatically by the trigger on every state change
- **ActivitatiTicket** — the time actually worked, distinct from calendar time
- **Personal** — the existing ASiS table; its key is `Marca`, a `char(6)`, not a
  numeric id

Table and column names stay in Romanian throughout, because they are the ones
already used by ASiS.

## ASiS conventions followed

**Procedure names** start from their role in the screen:

| Prefix | Role |
|---|---|
| `wIa…` | read (header, lines, journal) |
| `wScriu…` | insert and update |
| `wSterg…` | delete (spelled without the final "e", the way the database does it) |
| `wAC…` | autocomplete for lookup lists |
| `wOP…` | operations: exports, reports |
| `pAPILink…` | endpoint exposed through `asisservice` |

**The signature** is always `@sesiune varchar(50), @parXML xml`, and the user is
resolved with `wIaUtilizator`. The API endpoints are the exception: they
authenticate with a key (`validareCheieAPI`) instead of a session.

**Errors** are caught in `TRY…CATCH` and re-thrown with the procedure name
attached, so the message shown in the interface says where it came from.

## Field names are case-sensitive

The database collation is `SQL_Latin1_General_CP1_CI_AS`, so case does not
matter in T-SQL. **In XML it does.** A field name has to be spelled identically
in every place it travels through:

```
table column → alias in wIa* → grid DataField
             → form DataField → XQuery path in wScriu*
```

A single different letter makes the frame fail to find the attribute and leave
the field empty, with no error at all. Exceptions imposed by the frame, spelled
in lowercase: `@datajos`, `@datasus`, `@update`. `@nrPagina` and
`@nrItemsPerPagina`, on the other hand, are camelCase.

## Power BI dashboard

`AlfaSoftware.pbix` reads the `Tickete`, `Categorii`, `Prioritati` and
`Personal` tables, plus the indicator views from B5: `vw_RespectareSLA`,
`vw_TimpEfectiv_Responsabil` and `vw_TimpMediuRezolvare_Responsabil`. The
`Calendar` table does not come from SQL, it is built inside the model, so the
time axis stays continuous in months with no tickets.

The report is a single page:

- four cards: open tickets, resolved tickets, SLA compliance rate and average
  resolution time, in hours
- tickets per category, split by priority
- tickets received against tickets resolved, over time
- SLA compliance per category, plus a gauge on the total
- assignee workload: hours logged and tickets resolved
- slicers on period, category and assignee

The connection is saved with the server it was built against, so on first open
it has to be changed from *Transform data → Data source settings*, then
*Refresh*.

## Running it

The scripts execute in numeric order, against `Student8`. B1 and B2 run once;
the rest use `CREATE OR ALTER` and can be re-run at any time.

The API also needs an access key and the routes registered:

```sql
INSERT INTO service.CheiOAuth (access_token, alias, utilizator, dataora)
VALUES ('<your-key>', 'HELPDESK', '<user>', getdate())

INSERT INTO webConfigLinkuri (proceduraSql, codLink) VALUES
    ('pAPILinkTickete',   'hd_tickete'),
    ('pAPILinkTicketNou', 'hd_ticketnou')
```

The screens are configured in `webConfigTipuri`, `webConfigForm`,
`webConfigGrid` and `webConfigFiltre`, under the `TICKETING_APP` menu.
