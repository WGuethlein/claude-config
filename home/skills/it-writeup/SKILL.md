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

## Delivery format
The audience decides the format. A CIO or director opens what lands in their inbox; they don't render Markdown.
- Going to anyone other than Wyatt: deliver a finished file. Use .docx by default for memos and recommendations, PDF when the document is final and read-only, .xlsx when the deliverable is the data itself, and .pptx when it will be presented. Build it with the matching file skill (docx, pdf, xlsx, pptx).
- Markdown or a Claude Doc only for Wyatt's own working drafts, or when he asks for it.
- DLZ documents follow the DLZ design system. Read `C:\Projects\ClaudeDesignSystem\docs\brand-book\04-documents-and-presentations.md` before building. Start from the matching Word template: Memorandum for memos, Report for longer analyses. The .dotx files live on SharePoint; find them with the Microsoft 365 connector or ask Wyatt for the path. Use the template's named styles and keep its header and footer rather than formatting by hand.
- If no template is reachable, apply the theme values from that brand book (New Maroon headings, 11pt body, maroon table header row) and tell Wyatt the template was not used.
- In the Memorandum template, the Date / To / From / Subject fields come first; the Recommendation is the first paragraph after them.
