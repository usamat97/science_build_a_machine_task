#include <cstdint>
#include <cstdio>
#include <vector>
#include <chrono>

static constexpr int CHANNELS = 4;
static constexpr int TAPS = 16;
static constexpr int NUM_FRAMES = 1 << 20; // 1,048,576 input time steps

int main() {
    std::vector<int16_t> input(NUM_FRAMES * CHANNELS);
    std::vector<int32_t> output((NUM_FRAMES - TAPS + 1) * CHANNELS);

    // Fixed coefficients shared by all channels for now
    int16_t coeff[TAPS] = {
        3, -2, 5, 7,
        -1, 4, -3, 6,
        2, -5, 1, 3,
        -4, 2, 6, -2
    };

    // Deterministic input data
    for (int i = 0; i < NUM_FRAMES * CHANNELS; i++) {
        input[i] = static_cast<int16_t>((i * 17 + 13) % 2048 - 1024);
    }

    auto start = std::chrono::high_resolution_clock::now();

    int64_t checksum = 0;

    for (int n = TAPS - 1; n < NUM_FRAMES; n++) {
        int out_idx = n - (TAPS - 1);

        for (int ch = 0; ch < CHANNELS; ch++) {
            int32_t acc = 0;

            for (int k = 0; k < TAPS; k++) {
                int sample_idx = (n - k) * CHANNELS + ch;
                acc += static_cast<int32_t>(input[sample_idx]) *
                       static_cast<int32_t>(coeff[k]);
            }

            output[out_idx * CHANNELS + ch] = acc;
            checksum += acc;
        }
    }

    auto end = std::chrono::high_resolution_clock::now();

    double seconds = std::chrono::duration<double>(end - start).count();
    double output_samples = static_cast<double>(NUM_FRAMES - TAPS + 1) * CHANNELS;
    double ops_per_sec = output_samples / seconds;

    std::printf("CHECKSUM=%lld\n", static_cast<long long>(checksum));
    std::printf("SW_OPS_PER_SEC=%.2f\n", ops_per_sec);

    return 0;
}
