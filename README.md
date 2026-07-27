# AlfaSoftware — Helpdesk în ASiS ERP

Modul de helpdesk (ticketing) construit peste ASiS ERP, pe SQL Server.
Acoperă structura bazei, machetele CRUD din interfața web, indicatorii de
performanță, raportul Vizor și expunerea datelor prin API REST.

Baza de lucru: `Student8`.

## Structura fișierelor

Fiecare fișier corespunde unei etape din temă și se rulează în ordine.

| Fișier | Conținut |
|---|---|
| `SQLAlfaSoftwareA.sql` | Exerciții SQL pe baza existentă: SELECT, funcții, agregări, JOIN-uri, subinterogări și CTE, funcții fereastră, XML, DDL/CRUD |
| `SQLAlfaSoftwareB1.sql` | Structura bazei: 6 tabele cu chei străine și constrângeri CHECK |
| `SQLAlfaSoftwareB2.sql` | Date de test: nomenclatoare, tickete, jurnal, activități |
| `SQLAlfaSoftwareB3.sql` | Trigger de jurnalizare a schimbărilor de stare |
| `SQLAlfaSoftwareB4.sql` | 19 proceduri pentru machetele web: CRUD, autocomplete, export Excel |
| `SQLAlfaSoftwareB5.sql` | 7 view-uri și o procedură pentru indicatori |
| `SQLAlfaSoftwareB7.sql` | Raport Vizor cu grupări și subtotaluri |
| `SQLAlfaSoftwareB9-10.sql` | API REST: GET listă tickete, POST creare ticket |

## Modelul de date

```
Categorii ─┐
Prioritati ─┼─→ Tickete ─┬─→ JurnalTickete     (istoricul stărilor)
StariTicket ┘      │      └─→ ActivitatiTicket (munca raportată)
                   └──────────→ Personal        (solicitant, responsabil)
```

- **Tickete** — documentul central. Trece prin fluxul `Nou → Atribuit → In lucru → Rezolvat → Inchis`
- **JurnalTickete** — scris automat de trigger la fiecare schimbare de stare
- **ActivitatiTicket** — timpul efectiv lucrat, distinct de timpul calendaristic
- **Personal** — tabela ASiS existentă; cheia e `Marca`, de tip `char(6)`, nu un id numeric

## Convenții ASiS respectate

**Numele procedurilor** pornesc de la rolul lor în machetă:

| Prefix | Rol |
|---|---|
| `wIa…` | citire (antet, poziții, jurnal) |
| `wScriu…` | inserare și modificare |
| `wSterg…` | ștergere (fără „e", conform bazei) |
| `wAC…` | autocomplete pentru liste de selecție |
| `wOP…` | operații: export, rapoarte |
| `pAPILink…` | endpoint expus prin `asisservice` |

**Semnătura** e mereu `@sesiune varchar(50), @parXML xml`, iar utilizatorul se
obține cu `wIaUtilizator`. Excepție fac endpoint-urile de API, care se
autentifică prin cheie (`validareCheieAPI`), nu prin sesiune.

**Erorile** se prind în `TRY…CATCH` și se re-aruncă cu numele procedurii atașat,
ca mesajul din interfață să spună de unde vine.

## Numele câmpurilor sunt case-sensitive

Colația bazei e `SQL_Latin1_General_CP1_CI_AS`, deci în T-SQL majusculele nu
contează. **În XML contează.** Numele unui câmp trebuie scris identic în toate
locurile prin care trece:

```
coloana din tabelă → aliasul din wIa* → DataField din grid
                  → DataField din form → calea XQuery din wScriu*
```

O singură literă diferită face ca frame-ul să nu găsească atributul și să lase
câmpul gol, fără nicio eroare. Excepții impuse de frame, scrise cu litere mici:
`@datajos`, `@datasus`, `@update`. În schimb `@nrPagina` și `@nrItemsPerPagina`
sunt camelCase.

## Rulare

Scripturile se execută în ordinea numerelor, în `Student8`. B1 și B2 se rulează
o singură dată; restul folosesc `CREATE OR ALTER` și se pot re-rula oricând.

Pentru API mai trebuie o cheie de acces și înregistrarea rutelor:

```sql
INSERT INTO service.CheiOAuth (access_token, alias, utilizator, dataora)
VALUES ('<cheia-ta>', 'HELPDESK', '<utilizator>', getdate())

INSERT INTO webConfigLinkuri (proceduraSql, codLink) VALUES
    ('pAPILinkTickete',   'hd_tickete'),
    ('pAPILinkTicketNou', 'hd_ticketnou')
```

Machetele se configurează în `webConfigTipuri`, `webConfigForm`,
`webConfigGrid` și `webConfigFiltre`, pe meniul `TICKETING_APP`.