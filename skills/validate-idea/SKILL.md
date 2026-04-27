---
name: validate-idea
description: Use when someone mentions a product idea at ANY stage of clarity -- even vague preambles like "I've been thinking about building...", "I've been noodling on an idea", "I want to build something that...". Also triggers on "is this worth building", "is there a market", "is this stupid", "should I bother", demand validation, competitor concerns, or deciding startup vs side project. Invoke EARLY -- this skill structures vague ideas into concrete ones. Sits upstream of write-a-prd and grill-me.
---

# Validate Idea

Product validation before design. Determines whether an idea is worth building and for whom,
before entering the design/implementation pipeline (write-a-prd, prd-to-plan, etc.).

This is NOT a design skill. It produces a validated problem statement and premise list,
not a design doc or PRD. It answers "should we build this, and for whom?" not "how should
we build this?"

## When to Use

Invoke on ANY of these, even if the idea is vague or incomplete:

- "I have an idea for..."
- "I've been thinking about building..."
- "I've been noodling on..."
- "I want to build something that..."
- "Is this worth building?"
- "Is there a market for this?"
- "Should I build X or Y?"
- "Tell me if this is stupid"
- "Should I even bother?"
- "I'm thinking about starting a side project..."
- User describes a new product concept before any code exists
- User mentions competitors or market concerns about an unbuilt thing

**Trigger early.** This skill turns vague ideas into concrete ones. Don't wait for
a fully-formed concept -- that's what the questioning process produces.

## When NOT to Use

- Problem is already validated, user wants design: use `superpowers:brainstorming` or `write-a-prd`
- User wants to stress-test an existing plan: use `grill-me`
- User is already building and wants architecture help: use `improve-codebase-architecture`

## Process

### 1. Mode Selection

Ask via AskUserQuestion:

> What's your goal with this?
> A) **Startup / business** -- real users, real revenue, real validation needed
> B) **Builder** -- hackathon, side project, learning, open source, having fun

**A = Startup mode** (diagnostic, uncomfortable questions).
**B = Builder mode** (generative, enthusiastic collaboration).

### 2. Startup Mode: Forcing Questions

Assess product stage first:
- **Pre-product** (idea, no users): ask Q1, Q2, Q3
- **Has users** (using it, not paying): ask Q2, Q4, Q5
- **Has paying customers**: ask Q4, Q5, Q6

Ask ONE question at a time. Wait for the answer. Push until the answer is specific and
evidence-based. Vague answers get pushed harder.

#### Q1: Demand Reality
"What's the strongest evidence someone actually wants this -- not 'is interested,' not
'signed up for a waitlist,' but would be upset if it disappeared tomorrow?"

Push for: specific behavior, payment, expanded usage, panic when it breaks.
Red flags: "people say it's interesting," waitlist numbers, VC enthusiasm.

#### Q2: Status Quo
"What are your users doing right now to solve this -- even badly? What does that cost them?"

Push for: specific workflow, hours spent, dollars wasted, tools duct-taped together.
Red flags: "nothing exists" (if nobody's doing anything, the pain isn't real enough).

#### Q3: Desperate Specificity
"Name the actual human who needs this most. Title? What gets them promoted? Fired?"

Push for: a name, a role, a specific consequence. Something heard directly from them.
Red flags: category answers ("enterprises," "SMBs," "marketing teams"). You can't email a category.

#### Q4: Narrowest Wedge
"What's the smallest version someone would pay real money for -- this week, not after
you build the platform?"

Push for: one feature, one workflow, shippable in days not months.
Red flags: "we need the full platform first" (attached to architecture, not value).

#### Q5: Observation
"Have you sat down and watched someone use this without helping them? What surprised you?"

Push for: a specific surprise that contradicted assumptions.
Red flags: "we sent a survey," "nothing surprising" (not watching, or not paying attention).
Gold: users doing something the product wasn't designed for.

#### Q6: Future-Fit
"If the world looks meaningfully different in 3 years, does your product become more
essential or less?"

Push for: specific claim about how their users' world changes and why that helps.
Red flags: "market is growing 20% YoY" (every competitor says this), "AI makes everything better."

**Smart-skip:** If an earlier answer already covers a later question, skip it.

**Escape hatch:** If the user pushes to skip:
- First time: "The hard questions are the value. Two more, then we move."
  Ask the 2 most critical remaining questions for their stage.
- Second time: respect it, move to Premise Challenge.

### 3. Builder Mode: Generative Questions

Ask ONE at a time. Goal is to sharpen and excite, not interrogate.

- **Coolest version?** What would make this genuinely delightful?
- **Who would you show this to?** What makes them say "whoa"?
- **Fastest path to something usable or shareable?**
- **What existing thing is closest, and how is yours different?**
- **Unlimited time version?** What's the 10x?

Smart-skip applies. If the vibe shifts toward "this could be a real company," upgrade
to Startup mode.

### 4. Premise Challenge

Before handing off, challenge the premises:

1. **Right problem?** Could a different framing yield a simpler or higher-impact solution?
2. **What if we do nothing?** Real pain or hypothetical?
3. **What already exists?** Existing code, tools, patterns that partially solve this?
4. **Distribution?** If the deliverable is a new artifact, how do users get it?

Present premises as statements the user must agree/disagree with:
```
PREMISES:
1. [statement] -- agree/disagree?
2. [statement] -- agree/disagree?
3. [statement] -- agree/disagree?
```

If the user disagrees, revise and re-confirm.

### 5. Handoff

Summarize validated problem statement and agreed premises. Then recommend next step:

- **Startup mode, validated:** "Ready for a PRD. Use `write-a-prd` to formalize."
- **Startup mode, weak evidence:** "You have premises but weak demand evidence. Assignment:
  [one concrete real-world action] before writing a PRD."
- **Builder mode:** "Ready to design. Use `superpowers:brainstorming` to explore approaches."

Every startup-mode session ends with **one concrete assignment** -- a real-world action,
not "go build it."

## Anti-Sycophancy Rules

During questioning, NEVER say:
- "That's an interesting approach" -- take a position instead
- "There are many ways to think about this" -- pick one, state what evidence would change your mind
- "You might want to consider..." -- say "This is wrong because..." or "This works because..."
- "That could work" -- say whether it WILL work and what evidence is missing
- "I can see why you'd think that" -- if they're wrong, say so and why

ALWAYS:
- Take a position on every answer. State the position AND what would change it.
- Challenge the strongest version of the claim, not a strawman.
- Push once, then push again. The first answer is usually the polished version.
- Admit when a question is outside your experience. "I don't have good signal on
  this market" is more useful than a plausible-sounding industry analysis.

### Pushback Patterns

| Pattern | Weak Response | Rigorous Response |
|---------|--------------|-------------------|
| Vague market ("AI tool for developers") | "Big market! What kind?" | "10,000 AI dev tools exist. What specific task wastes 2+ hours/week? Name the person." |
| Social proof ("everyone loves it") | "Who specifically?" | "Loving an idea is free. Has anyone paid? Asked when it ships? Gotten angry when it broke?" |
| Platform vision ("need the full platform") | "What's a stripped-down version?" | "Red flag. If no one gets value from a smaller version, the value prop isn't clear yet." |
| Growth stats ("20% YoY growth") | "Strong tailwind!" | "Every competitor cites that stat. What's YOUR thesis about how this market changes for YOU?" |
| Undefined terms ("seamless onboarding") | "What's your current flow?" | "'Seamless' isn't a feature. What step causes drop-off? What's the rate? Have you watched it?" |
