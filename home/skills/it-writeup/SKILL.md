---
name: it-writeup
description: Write a leadership-facing memo, analysis, recommendation, or decision document for DLZ. Use this whenever Wyatt asks for a write-up, summary for leadership, recommendation, options analysis, licensing or vendor comparison, policy proposal, or "something I can send to" a director, the CIO, or a committee. Also use it when he's deciding between options (Copilot vs Claude, renew vs replace, tool A vs tool B) and wants it on paper. Not for status reports, runbooks, or change requests, which have their own skills.
---
# IT write-up

Leadership reads the first paragraph and the recommendation; everything else is support. Write for a non-technical executive first and put the technical detail where an engineer can find it.

## Before writing
- Confirm the audience (CIO, directors, a committee, a vendor) and the decision being asked for. If no decision is being asked for, say so; it may just be a status report.
- Pull numbers from source data (exports, usage reports, invoices) rather than memory. Cite the source and date next to every figure.
- Ask for anything missing that changes the recommendation. Don't ask for anything that doesn't.

## Structure
```
# <Title>
**Recommendation:** one or two sentences, with the cost and the date it needs a decision by.

## Summary
Three to five sentences: the situation, what changes if we do nothing, what we propose.

## Findings
Numbered. Each finding is one claim plus its evidence and source.

## Options
Table: option, cost, effort, risk, what we give up. Include "do nothing".

## Risks and compliance
Security, CUI/CMMC, audit, licensing, or contractual implications. Say "none identified" explicitly if so.

## Next steps
Owner, action, date.

## Appendix
Data tables, methodology, assumptions.
```

## Style
- No emojis. Plain prose. Bullets and tables only where they carry real structure.
- Dollar figures and seat counts are exact; growth and savings are ranges with the assumption stated.
- Name trade-offs honestly. A recommendation that hides the downside gets reversed later.
- Deliver as a Claude Doc or .md unless Wyatt names a format. Offer a .docx export only when it is going outside IT.
