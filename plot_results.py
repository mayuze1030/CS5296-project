# plot_results.py
import matplotlib.pyplot as plt
import numpy as np

modes = ['Native', 'Bridge', 'Host', 'Container']

# Actual test results
tcp_means = [4.968, 4.776, 4.967, 4.781]
tcp_stds  = [0.001, 0.014, 0.001, 0.004]

rtt_means = [0.157, 0.306, 0.156, 0.181]
rtt_stds  = [0.002, 0.021, 0.002, 0.004]

fig, axes = plt.subplots(1, 2, figsize=(14, 6))

x = np.arange(len(modes))

bars1 = axes[0].bar(x, tcp_means, yerr=tcp_stds, capsize=5,
                     color=['#2196F3', '#FF9800', '#4CAF50', '#9C27B0'])
axes[0].set_xlabel('Network Mode')
axes[0].set_ylabel('Throughput (Gbps)')
axes[0].set_title('TCP Throughput Comparison')
axes[0].set_xticks(x)
axes[0].set_xticklabels(modes)
axes[0].set_ylim(0, 5.5)

bars2 = axes[1].bar(x, rtt_means, yerr=rtt_stds, capsize=5,
                     color=['#2196F3', '#FF9800', '#4CAF50', '#9C27B0'])
axes[1].set_xlabel('Network Mode')
axes[1].set_ylabel('RTT (ms)')
axes[1].set_title('Ping Latency Comparison')
axes[1].set_xticks(x)
axes[1].set_xticklabels(modes)

plt.tight_layout()
plt.savefig('network_comparison.png', dpi=150)
print("Chart saved: network_comparison.png")
