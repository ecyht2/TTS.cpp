### Overview

This script converts a 32bit floating point TTS.cpp GGUF model file to a quantized format. [Quantization](https://huggingface.co/docs/optimum/en/concept_guides/quantization) is a technique used to miniturize weight and bias values in order to reduce overhead memory requirements and reduce inference time. Typically the extent of quantization results in a proportionate though minor impact to model proficiency.

**WARNING** Full QA has not been completed for quantization. Some quantization types are not functioning as expected.

### Requirements

* quantize and the parler library must be built 
* A local GGUF file for parler tts mini

### Usage

In order to get a detailed breakdown the functionality currently available you can call the cli with the `--help` parameter. This will return a breakdown of all parameters:
```commandline
./quantize --help

--quantized-type (-qt):
    The ggml enum of the quantized type to convert compatible model tensors to. For more information see readme. Defaults to Q4_0 quantizatio (2).
--n-threads (-nt):
    The number of cpu threads to run the quantization process with. Defaults to known hardware concurrency.
--model-path (-mp):
    (REQUIRED) The local path of the gguf model file for Parler TTS mini v1 to quantize.
--quantized-model-path (-qp):
    (REQUIRED) The path to save the model in a quantized format.
```

General usage should follow from these possible parameters. E.G. The following command will save a quantized version of the model using Q4_0 quantization to `/model/path/to/new/gguf_file_q.gguf`:

```commandline
./quantize --model-path /model/path/to/gguf_file.gguf --quantized-model-path /model/path/to/new/gguf_file_q.gguf --quantized-type 2 
```
Valid types passed to `--quantized-type` are described by the `ggml_type` enum in GGML:

```cpp
        GGML_TYPE_Q4_0    = 2,
        GGML_TYPE_Q4_1    = 3,
        // GGML_TYPE_Q4_2 = 4, support has been removed
        // GGML_TYPE_Q4_3 = 5, support has been removed
        GGML_TYPE_Q5_0    = 6,
        GGML_TYPE_Q5_1    = 7,
        GGML_TYPE_Q8_0    = 8,
        GGML_TYPE_Q8_1    = 9,
        GGML_TYPE_Q2_K    = 10,
        GGML_TYPE_Q3_K    = 11,
        GGML_TYPE_Q4_K    = 12,
        GGML_TYPE_Q5_K    = 13,
        GGML_TYPE_Q6_K    = 14,
        GGML_TYPE_Q8_K    = 15,
        GGML_TYPE_IQ2_XXS = 16,
        GGML_TYPE_IQ2_XS  = 17,
        GGML_TYPE_IQ3_XXS = 18,
        GGML_TYPE_IQ1_S   = 19,
        GGML_TYPE_IQ4_NL  = 20,
        GGML_TYPE_IQ3_S   = 21,
        GGML_TYPE_IQ2_S   = 22,
        GGML_TYPE_IQ4_XS  = 23,
        GGML_TYPE_I8      = 24,
        GGML_TYPE_Q4_0_4_4 = 31,
        GGML_TYPE_Q4_0_4_8 = 32,
        GGML_TYPE_Q4_0_8_8 = 33,
        GGML_TYPE_TQ1_0   = 34,
        GGML_TYPE_TQ2_0   = 35,
```

### Findings

In general results with quantization have thus far been mixed. While the model does not completely degrade with full quantization, it more frequently repeats words, rarely maintains tonal consistency, and sometimes lengthens speech production unnecessarily. Some improvement is observed when the embeddings and channel heads are not quantized, but the model still often produces unnecessary audio tokens.

#### Performance Observations

A clear improvment in tokens per second via the generative model is observed with quantization. Seen below with Q5_0 quantization, the model is now capable of completing its generation in real time (it generates tokens faster than it takes to listen to them), and the model's TPS has improved from ~693 to ~916.

```
Mean Stats:

  Generation Time (ms):      4089.173764
  Decode Time (ms):          5806.669719
  Generation TPS:            915.998475
  Decode TPS:                575.483766
  Generation by output (ms): 0.847787
  Decode by output (ms):     1.350455
```