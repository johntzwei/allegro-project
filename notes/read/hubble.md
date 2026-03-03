# Hubble — Reference for Experiments

**Paper:** https://arxiv.org/abs/2510.19811 (Oct 2025)
**Authors:** Wei, Godbole, Khan, Wang, Zhu, Flemings, Kashyap, Gummadi, Neiswanger, Jia

## Model Suite Design

### Core Models (8 total, 2x2x2 factorial)

| Model Size | Training Tokens | Condition   |
|-----------|----------------|-------------|
| 1B        | 100B           | Standard    |
| 1B        | 100B           | Perturbed   |
| 1B        | 500B           | Standard    |
| 1B        | 500B           | Perturbed   |
| 8B        | 100B           | Standard    |
| 8B        | 100B           | Perturbed   |
| 8B        | 500B           | Standard    |
| 8B        | 500B           | Perturbed   |

- **Architecture:** Llama 3-based, OLMo tokenizer (50K vocab), untied embeddings
- **8B variant:** 36 layers (not 32) for GPU utilization
- **Training data:** DCLM (deduplicated CommonCrawl). 100B corpus is a prefix of the 500B corpus.

### Timing Models (6 models, all 1B/100B)

Perturbations inserted during specific training windows (in billions of tokens):
- (0, 50), (50, 100), (0, 25), (25, 50), (50, 75), (75, 100)

These study when data is seen during training and whether it is forgotten.

## Perturbation Design

**Standard models** = trained on clean DCLM only.
**Perturbed models** = same DCLM corpus + controlled insertions of known text.

Each perturbation example is assigned a **duplication level**: {0x, 1x, 4x, 16x, 64x, 256x}.
- Insertions are spliced between documents, surrounded by EOS tags, matching normal document formatting.
- At most one perturbation per training sequence.
- Total perturbation volume: ~0.08% of 100B corpus, ~0.016% of 500B corpus.
- Base corpus is decontaminated against all perturbation text.

### What This Means for Experiments

For any inserted example, we know:
1. **Whether** the model saw it (standard=no, perturbed=yes at assigned dup level)
2. **How many times** it was seen (0x, 1x, 4x, 16x, 64x, 256x)
3. **When** during training it was seen (timing models only)

The standard model serves as a **negative control** (never saw perturbation data).

## Test Set Contamination — Inserted Benchmarks

The following benchmark test sets were inserted as perturbations:

| Benchmark   | Format Inserted | Eval Method |
|-------------|----------------|-------------|
| PopQA       | QA pairs       | Exact match (generative) |
| Winogrande  | Two formats (original + reformatted) | Zero-shot accuracy (loss-based choice) |
| MMLU        | Multiple choice | Zero-shot accuracy (loss-based choice) |
| HellaSwag   | Multiple choice | Zero-shot accuracy (loss-based choice) |
| PIQA        | Multiple choice | Zero-shot accuracy (loss-based choice) |
| ELLie       | (format TBD)   | Zero-shot accuracy |
| MUNCH       | (format TBD)   | Zero-shot accuracy |

### Key TSC Findings from the Paper

- Models begin memorizing test examples at **1x duplication**.
- Memorizing specific test examples **does not generalize to the task** — it inflates scores on seen items only.
- **WinoGrande format experiment:** When contaminated in one format but tested in another, accuracy on contaminated items is *worse* than on unseen items. Contamination is format-brittle.
- Larger models (8B > 1B) memorize more at the same duplication level.
- More training data (500B > 100B) dilutes memorization at the same duplication level.

## Evaluation Methods Used

1. **Loss-based:** Compute log-likelihood on inserted text, normalize by length. Compare perturbed vs standard model.
2. **Loss-based choice:** For MC benchmarks, compute loss per answer option, pick lowest. Standard zero-shot eval.
3. **Generative:** Prompt with prefix, generate tokens, score via exact match or word recall.

## MIA Benchmark (HubbleMIA)

Ground-truth membership labels from the perturbation design enable clean MIA evaluation.
- **Attacks tested:** Loss, MinK%, MinK%++, Zlib
- **Best attack:** MinK%++ — near-perfect AUC at 256x dup, near-random at 1x dup.
- Useful for evaluating contamination *detection* methods.

## Key Variables for Designing Experiments

| Variable | Values | Effect |
|----------|--------|--------|
| Model size | 1B, 8B | Larger = more memorization |
| Corpus size | 100B, 500B | Larger = dilutes memorization |
| Duplication | 0x–256x | More = more memorization |
| Training phase | Early/late (timing models) | Early insertions are forgotten |
| Eval format | Same/different from training | Memorization is format-specific |
| Standard vs perturbed | Control vs treatment | Causal identification |
