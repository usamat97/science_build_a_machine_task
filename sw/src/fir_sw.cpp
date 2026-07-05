#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <chrono>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>

static constexpr int CHANNELS = 4;
static constexpr int TAPS = 16;
static constexpr int REPEAT = 200;

int main() {
    std::ifstream input_file("fir_input.txt");
    if (!input_file) {
        std::fprintf(stderr, "ERROR: could not open fir_input.txt\n");
        return 1;
    }

    std::vector<uint64_t> input_words;
    std::string line;

    while (input_file >> line) {
        uint64_t word = std::stoull(line, nullptr, 16);
        input_words.push_back(word);
    }

    const int num_frames = static_cast<int>(input_words.size());
    if (num_frames < TAPS) {
        std::fprintf(stderr, "ERROR: need at least %d input frames\n", TAPS);
        return 1;
    }

    const int out_frames = num_frames - TAPS + 1;

    std::vector<int16_t> input(num_frames * CHANNELS);
    std::vector<int32_t> output(out_frames * CHANNELS);

    for (int n = 0; n < num_frames; n++) {
        uint64_t w = input_words[n];
        input[n * CHANNELS + 0] = static_cast<int16_t>((w >> 0)  & 0xFFFF);
        input[n * CHANNELS + 1] = static_cast<int16_t>((w >> 16) & 0xFFFF);
        input[n * CHANNELS + 2] = static_cast<int16_t>((w >> 32) & 0xFFFF);
        input[n * CHANNELS + 3] = static_cast<int16_t>((w >> 48) & 0xFFFF);
    }

    alignas(32) int16_t coeff[TAPS] = {
        3, -2, 5, 7,
        -1, 4, -3, 6,
        2, -5, 1, 3,
        -4, 2, 6, -2
    };

    volatile int64_t checksum = 0;

    auto start = std::chrono::high_resolution_clock::now();

    for (int r = 0; r < REPEAT; r++) {
        int64_t local_checksum = 0;

        for (int n = TAPS - 1; n < num_frames; n++) {
            int out_idx = n - (TAPS - 1);

            for (int ch = 0; ch < CHANNELS; ch++) {
                int32_t acc = 0;

                acc += static_cast<int32_t>(input[(n - 0)  * CHANNELS + ch]) * coeff[0];
                acc += static_cast<int32_t>(input[(n - 1)  * CHANNELS + ch]) * coeff[1];
                acc += static_cast<int32_t>(input[(n - 2)  * CHANNELS + ch]) * coeff[2];
                acc += static_cast<int32_t>(input[(n - 3)  * CHANNELS + ch]) * coeff[3];
                acc += static_cast<int32_t>(input[(n - 4)  * CHANNELS + ch]) * coeff[4];
                acc += static_cast<int32_t>(input[(n - 5)  * CHANNELS + ch]) * coeff[5];
                acc += static_cast<int32_t>(input[(n - 6)  * CHANNELS + ch]) * coeff[6];
                acc += static_cast<int32_t>(input[(n - 7)  * CHANNELS + ch]) * coeff[7];
                acc += static_cast<int32_t>(input[(n - 8)  * CHANNELS + ch]) * coeff[8];
                acc += static_cast<int32_t>(input[(n - 9)  * CHANNELS + ch]) * coeff[9];
                acc += static_cast<int32_t>(input[(n - 10) * CHANNELS + ch]) * coeff[10];
                acc += static_cast<int32_t>(input[(n - 11) * CHANNELS + ch]) * coeff[11];
                acc += static_cast<int32_t>(input[(n - 12) * CHANNELS + ch]) * coeff[12];
                acc += static_cast<int32_t>(input[(n - 13) * CHANNELS + ch]) * coeff[13];
                acc += static_cast<int32_t>(input[(n - 14) * CHANNELS + ch]) * coeff[14];
                acc += static_cast<int32_t>(input[(n - 15) * CHANNELS + ch]) * coeff[15];

                output[out_idx * CHANNELS + ch] = acc;
                local_checksum += acc;
            }
        }

        checksum += local_checksum;
    }

    auto end = std::chrono::high_resolution_clock::now();

    double seconds = std::chrono::duration<double>(end - start).count();
    double output_samples = static_cast<double>(out_frames) * CHANNELS * REPEAT;
    double ops_per_sec = output_samples / seconds;

    std::ofstream output_file("sw/output/sw_output.txt");
    if (!output_file) {
        std::fprintf(stderr, "ERROR: could not open sw/output/sw_output.txt\n");
        return 1;
    }

    output_file << std::hex << std::setfill('0');
    for (int n = 0; n < out_frames; n++) {
        uint32_t y0 = static_cast<uint32_t>(output[n * CHANNELS + 0]);
        uint32_t y1 = static_cast<uint32_t>(output[n * CHANNELS + 1]);
        uint32_t y2 = static_cast<uint32_t>(output[n * CHANNELS + 2]);
        uint32_t y3 = static_cast<uint32_t>(output[n * CHANNELS + 3]);

        output_file
            << std::setw(8) << y3
            << std::setw(8) << y2
            << std::setw(8) << y1
            << std::setw(8) << y0
            << '\n';
    }

    std::printf("INPUT_FRAMES=%d\n", num_frames);
    std::printf("OUTPUT_FRAMES=%d\n", out_frames);
    std::printf("CHECKSUM=%lld\n", static_cast<long long>(checksum));
    std::printf("SW_OPS_PER_SEC=%.2f\n", ops_per_sec);

    return 0;
}
