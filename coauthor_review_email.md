Subject: ParCC v1.4 Manuscript - Co-author Review Required (Action by: [DATE])

---

Dear Co-authors,

Please find attached the manuscript describing ParCC v1.4 and the accompanying validation workbook. This is the first circulation of this manuscript and I am requesting your thorough review before we proceed with journal submission.

**Attached files:**
1. ParCC_Manuscript_v1.4.docx - Full manuscript (~6,700 words)
2. ParCC_Validation_TestCases_v1.4.xlsx - Supplementary validation workbook (51 test cases)

Please also review the live application and documentation:
- App: https://019d0dce-b522-bb76-f20b-8cfa598859a4.share.connect.posit.cloud/
- Documentation: https://drpakhare.github.io/ParCC/
- Source code: https://github.com/drpakhare/ParCC

---

### Review Guidance

Since this is your first look at the manuscript, I would appreciate a comprehensive review. Below are specific areas where your expertise is particularly needed.

**1. Overall narrative and framing**
Does the paper make a convincing case for why ParCC exists? The Introduction argues that HTA parameter conversion is fragmented, error-prone, and poorly documented. Please assess whether this framing is accurate, fair, and well-supported — or whether it overstates the problem. Are there existing tools or packages we have failed to acknowledge?

**2. Design principles and architecture (Methods)**
The paper claims four design principles (Integration, Transparency, Education, Accessibility). Please evaluate whether the platform actually delivers on these claims. If you have used ParCC and found gaps between what the paper promises and what the tool does, flag them.

**3. Mathematical accuracy**
Table 2 lists 25 formulas. Please verify any formulas within your area of expertise. In particular:
- Are the rate-probability and HR conversion formulas correctly stated and properly attributed?
- Are the survival extrapolation descriptions (Weibull, Log-Logistic) accurate?
- Are the PSA distribution fitting descriptions (Beta, Gamma, LogNormal, Dirichlet) correct?
- Are the BIA and PPP conversion descriptions methodologically sound?

**4. Module descriptions (Platform Features section)**
Each module gets a descriptive subsection. Please check whether these descriptions accurately reflect what the tool actually does. Test a few modules in the live app against what the paper claims.

**5. Practical application scenarios**
The paper includes four scenarios:
- Scenario 1: Markov model parameterisation from PLATO trial HRs
- Scenario 2: TB diagnostic deployment decision
- Scenario 3: Systematic review bulk conversion
- Scenario 4: Cross-country cost transferability (UK to India)

Are these realistic? Would an HTA practitioner actually use ParCC this way? If you have a real-world example from your own work that could replace or strengthen any scenario, that would significantly improve credibility.

**6. Discussion and limitations**
Does the Discussion accurately position ParCC relative to existing tools (TreeAge, R packages, Excel)? Are all meaningful limitations acknowledged? Please add any limitations you have encountered in practice that are missing.

**7. Validation workbook**
The Excel file contains 51 test cases across 15 module sheets. Please independently verify at least 3-4 test cases against your own manual calculations or against the live app. The workbook is intended as supplementary material — it must be independently reproducible.

**8. References**
19 references are cited. Please check whether key methodological sources are missing, and whether citations are used appropriately in context.

---

### Important: AI Use Disclosure

I want to be fully transparent about how this manuscript was produced.

**What was AI-assisted:**
- The ParCC application code was architected and generated with LLM assistance (Google Gemini, Anthropic Claude), under researcher supervision — this is already acknowledged in the manuscript.
- The manuscript draft was generated with substantial AI assistance (Anthropic Claude). This includes the prose text of all sections, table structures, and the validation workbook design.
- The vignettes on the documentation site were similarly AI-assisted.

**What this means for co-authors:**
By adding your name to this paper, you take intellectual responsibility for its content. AI-generated text can be fluent and plausible-sounding while being subtly wrong — in framing, in emphasis, in what it chooses to highlight or omit. This is why your independent critical review is essential, not ceremonial.

**Sections that most need human authorship and judgement:**

- **Introduction (entire section)** — The argument for why ParCC is needed must reflect our genuine assessment of the field. An AI can construct a reasonable-sounding gap analysis, but only domain experts can judge whether the gap is real, whether we've been fair to existing tools, and whether our framing is honest.

- **Discussion (entire section)** — This is where we interpret our own work. Claims about significance, comparisons with alternatives, and assessment of impact must be defensible by the authors, not merely generated by a model.

- **Limitations** — AI tends to produce balanced, diplomatic limitations. Please add real limitations you've encountered. What doesn't work well? What frustrated you? What would you not trust ParCC to do?

- **Practical scenarios** — These were generated as illustrations. Real examples from actual HTA projects would be far more valuable. If you've used ParCC (or could use it) for a real analysis, even a small one, please consider contributing that.

- **Conclusion** — This represents our collective scientific judgement about what we have built and what it means. It should be written or substantially edited by human authors.

**Proposed disclosure for submission:**

> "The ParCC application was architected and code-generated with the assistance of large language models (Google Gemini, Anthropic Claude), under the supervision of RRC-HTA researchers. The initial manuscript draft was prepared with AI assistance and subsequently reviewed, revised, and validated by all named authors. All authors take full responsibility for the accuracy and integrity of the final submitted manuscript."

Please confirm you are comfortable with this wording, or suggest alternatives.

---

### What I Need From You

1. **Track-changes edits** on the manuscript — substantive comments, not just typo fixes
2. **Specific feedback** on the areas listed above
3. **Confirmation** that you have reviewed the live application, not just the paper
4. **Your position** on the AI use disclosure
5. **Any real-world examples** from your HTA work that could strengthen the scenarios
6. **Your approval** to be listed as a co-author, with the understanding of shared responsibility for content

Please return your comments by **[DATE]**. If you need more time, let me know — but please do respond either way so I know the timeline.

Thank you for your time and careful attention.

Best regards,
Abhijit Pakhare
Regional Resource Centre for Health Technology Assessment
AIIMS Bhopal
