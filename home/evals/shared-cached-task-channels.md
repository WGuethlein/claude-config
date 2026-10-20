# Eval: a shared cached Task has more channels than you are thinking about

## Why this exists

During the BenefitRecon desktop-app build (2026-09-03), a single 120-line class,
`CachedDeductionSource`, produced four defects across three consecutive review rounds. Every one was
the same shape: a channel flowing through a shared cached `Task` was wired to whichever caller happened
to arrive first, or to whichever caller happened to still be alive. Each fix addressed one channel and
left or created another.

The class does one simple thing: it caches an expensive fetch so several callers share one API call.
That is a common pattern. The reason it went wrong four times is that a shared task carries traffic in
both directions, and reasoning about one direction at a time feels complete while being wrong.

The four defects, in the order they were found:

1. **Progress in.** The interface had no progress parameter at all, so the step the fetch was supposed
   to report was unreachable. The screen that existed to show a multi-minute wait could never receive
   it.
2. **Progress in, part two.** After adding the parameter, the fetch captured the FIRST caller's
   progress. The first caller was a background prefetch with no UI, so the screen that joined later and
   actually needed the reports got nothing.
3. **Cancellation out.** `await sharedTask` ignored the awaiting caller's own token, and the shared
   fetch was started with the starter's token. A joiner cancelling did nothing; a starter cancelling
   killed a fetch other callers were awaiting.
4. **A derived timestamp, three times.** Set on every call including cache hits, so data looked
   permanently fresh. Then gated on a flag local to the starting caller's stack, so a starter
   cancelling mid-fetch lost the stamp entirely. Then stamped by an orphaned fetch after a newer one
   had already completed, overwriting a newer time with an older one.

## The check

Before accepting any implementation that caches a `Task` (or a promise, or a future) so multiple callers
share one operation, answer all five in writing. A design that cannot answer one of them is not done.

1. **What flows IN to the operation from a caller?** Progress, cancellation, a logger, a correlation id,
   an auth token. For each: does it come from the caller who STARTED the operation, or the caller
   currently waiting on it? If those differ, which is correct, and what happens to the other one?

2. **What flows OUT to each caller?** The result is obvious. Cancellation of an individual caller's wait
   is not. Does each caller observe its own token, or is it stuck until the shared operation finishes?

3. **Who owns cancelling the shared operation itself?** If any single caller can cancel it, that caller
   can cancel work others are waiting on. If nobody can, it runs to completion even when abandoned —
   which is often the right answer for an operation whose cost is already spent, but it must be a
   decision, not an accident.

4. **Who observes a fault, and what if nobody is left?** Wrapping the shared task per caller (a
   `WaitAsync`, a linked token, a timeout) decouples every caller from the shared task's exception. If
   all callers leave before it faults, the exception can be swallowed at finalization: no crash, no log,
   and a real failure disappears.

5. **Is any derived state — a timestamp, a row count, a status — written by the operation or by a
   caller?** Anything written by a caller is lost when that caller dies and duplicated when several
   arrive. Anything written by the operation must check that it is still the CURRENT operation before
   writing, or a stale run will overwrite a newer one. Tie derived state to the work, then guard it with
   a generation.

6. **Is the cache's own bookkeeping safe under concurrent callers, or does correctness depend on a
   single-threaded caller — and if so, where is that constraint enforced rather than merely hoped
   for?** The fields that track the shared operation are themselves shared state: the task reference,
   the generation counter, the current listener. `++generation` is not atomic and neither is a
   reference assignment paired with a later read. Every one of questions 1 to 5 can be answered
   correctly and the implementation can still hand a caller stale or wrong data through a plain data
   race on this bookkeeping.

   **This question was added because the first five missed it.** They were written after fixing a
   single-threaded, UI-thread-only implementation, and they inherited that assumption without stating
   it. The next use of this pattern in a concurrent context — an HTTP action, a background service with
   overlapping requests — would sail through questions 1 to 5 and still be broken. If the answer is
   "single-threaded by contract", that contract belongs in the type's own remarks, not in the head of
   whoever wrote it.

7. **Is the cached RESULT itself immutable?** A cached `Task<T>` hands every caller the same `T`. If
   that `T` is mutable, one caller mutating it corrupts it for all the others, including callers that
   already returned. An `IReadOnlyList<T>` interface is not a guarantee — check what the concrete
   object is.

## A known limitation of the reference implementation

`_listener` is "latest caller wins" and is never reset when that caller leaves. So if caller B joins,
becomes the listener, and then cancels its own wait, an earlier caller A still awaiting the shared fetch
receives no further progress at all — nothing re-attaches it. In the application this was written for
that has no observable effect: one screen is active at a time, and the only other caller is a background
prefetch that passes no progress anyway. It is recorded here because questions 1 and 2 treat the
in-channel as a two-party relationship, starter against current waiter, when it is really an ordered set
of overlapping listeners. If you are answering these questions for a case with genuinely concurrent
listeners, that framing is too narrow and you need a listener set rather than a single field.

## The lesson that generalises

The specific fixes matter less than the reason the reviews kept finding more: each fix was verified
against the defect it targeted, not against the class of defect it belonged to. "Fixed the progress
capture" was true and "fixed the shared-task channel wiring" was not, and the difference was invisible
until the next review.

When a second defect of the same shape appears in the same unit, stop fixing instances. Enumerate the
dimension — here, "channels through a shared task" — and check every position along it at once.

## How to use this

Run the five questions against the implementation, not the plan. Report each as answered or unanswered,
with the file and line that answers it. An unanswered question is a finding, at Important or above.

Reference implementation of the answers, for what a resolved version looks like:
`C:\Projects\Dayforce\src\Dlz.BenefitRecon.Infrastructure\Reconciliation\CachedDeductionSource.cs`
