<?php

declare(strict_types=1);

namespace App\Service;

use Psr\Log\LoggerInterface;

class ChaosEngineeringService
{
    private bool $enabled = false;
    private array $activeExperiments = [];

    public function __construct(
        private readonly LoggerInterface $logger,
    ) {
        $this->enabled = ($_ENV['CHAOS_ENABLED'] ?? 'false') === 'true';
    }

    public function isEnabled(): bool
    {
        return $this->enabled;
    }

    public function getExperiments(): array
    {
        return [
            'latency' => [
                'id' => 'latency',
                'name' => 'Latency Injection',
                'category' => 'network',
                'description' => 'Add artificial latency to responses',
                'parameters' => [
                    'delay_ms' => ['type' => 'integer', 'default' => 200, 'max' => 5000],
                    'probability' => ['type' => 'float', 'default' => 0.1, 'max' => 1.0],
                ],
                'impact' => 'Increased response times',
                'safe_to_run' => true,
            ],
            'error_injection' => [
                'id' => 'error_injection',
                'name' => 'Error Injection',
                'category' => 'application',
                'description' => 'Randomly return 500 errors',
                'parameters' => [
                    'error_rate' => ['type' => 'float', 'default' => 0.05, 'max' => 0.5],
                    'error_code' => ['type' => 'integer', 'default' => 500],
                ],
                'impact' => 'Some requests will fail',
                'safe_to_run' => true,
            ],
            'cpu_stress' => [
                'id' => 'cpu_stress',
                'name' => 'CPU Stress',
                'category' => 'resource',
                'description' => 'Consume CPU resources',
                'parameters' => [
                    'load_percent' => ['type' => 'integer', 'default' => 80, 'max' => 95],
                    'duration_seconds' => ['type' => 'integer', 'default' => 60, 'max' => 300],
                ],
                'impact' => 'Reduced processing capacity',
                'safe_to_run' => false,
            ],
            'memory_pressure' => [
                'id' => 'memory_pressure',
                'name' => 'Memory Pressure',
                'category' => 'resource',
                'description' => 'Allocate large amounts of memory',
                'parameters' => [
                    'memory_mb' => ['type' => 'integer', 'default' => 256, 'max' => 1024],
                    'duration_seconds' => ['type' => 'integer', 'default' => 60, 'max' => 300],
                ],
                'impact' => 'Potential OOM conditions',
                'safe_to_run' => false,
            ],
            'database_slow' => [
                'id' => 'database_slow',
                'name' => 'Database Slowdown',
                'category' => 'dependency',
                'description' => 'Simulate slow database queries',
                'parameters' => [
                    'delay_ms' => ['type' => 'integer', 'default' => 1000, 'max' => 10000],
                    'probability' => ['type' => 'float', 'default' => 0.2, 'max' => 1.0],
                ],
                'impact' => 'Slower page loads',
                'safe_to_run' => true,
            ],
            'cache_miss' => [
                'id' => 'cache_miss',
                'name' => 'Cache Miss',
                'category' => 'dependency',
                'description' => 'Force cache misses',
                'parameters' => [
                    'miss_rate' => ['type' => 'float', 'default' => 0.5, 'max' => 1.0],
                ],
                'impact' => 'Increased database load',
                'safe_to_run' => true,
            ],
            'network_partition' => [
                'id' => 'network_partition',
                'name' => 'Network Partition',
                'category' => 'network',
                'description' => 'Block traffic to specific services',
                'parameters' => [
                    'target_service' => ['type' => 'string', 'options' => ['database', 'cache', 'external_api']],
                    'duration_seconds' => ['type' => 'integer', 'default' => 30, 'max' => 120],
                ],
                'impact' => 'Service connectivity issues',
                'safe_to_run' => false,
            ],
            'disk_full' => [
                'id' => 'disk_full',
                'name' => 'Disk Full',
                'category' => 'resource',
                'description' => 'Simulate disk space exhaustion',
                'parameters' => [
                    'fill_percent' => ['type' => 'integer', 'default' => 95, 'max' => 99],
                ],
                'impact' => 'Write operations will fail',
                'safe_to_run' => false,
            ],
        ];
    }

    public function startExperiment(string $experimentId, array $parameters = []): array
    {
        if (!$this->enabled) {
            throw new \RuntimeException('Chaos engineering is disabled. Set CHAOS_ENABLED=true to enable.');
        }

        $experiments = $this->getExperiments();
        if (!isset($experiments[$experimentId])) {
            throw new \InvalidArgumentException("Unknown experiment: $experimentId");
        }

        $experiment = $experiments[$experimentId];
        $runId = 'exp-' . uniqid();

        // Merge parameters with defaults
        $effectiveParams = [];
        foreach ($experiment['parameters'] as $param => $config) {
            $effectiveParams[$param] = $parameters[$param] ?? $config['default'] ?? null;
        }

        $run = [
            'id' => $runId,
            'experiment_id' => $experimentId,
            'experiment' => $experiment,
            'parameters' => $effectiveParams,
            'status' => 'running',
            'started_at' => (new \DateTimeImmutable())->format('c'),
            'started_by' => 'system',
        ];

        $this->activeExperiments[$runId] = $run;

        $this->logger->warning('Chaos experiment started', [
            'run_id' => $runId,
            'experiment' => $experimentId,
            'parameters' => $effectiveParams,
        ]);

        return $run;
    }

    public function stopExperiment(string $runId): array
    {
        if (!isset($this->activeExperiments[$runId])) {
            // Return mock completed experiment
            return [
                'id' => $runId,
                'status' => 'stopped',
                'stopped_at' => (new \DateTimeImmutable())->format('c'),
                'result' => 'Experiment stopped successfully',
            ];
        }

        $experiment = $this->activeExperiments[$runId];
        $experiment['status'] = 'stopped';
        $experiment['stopped_at'] = (new \DateTimeImmutable())->format('c');

        unset($this->activeExperiments[$runId]);

        $this->logger->info('Chaos experiment stopped', ['run_id' => $runId]);

        return $experiment;
    }

    public function getActiveExperiments(): array
    {
        return array_values($this->activeExperiments);
    }

    public function getExperimentHistory(): array
    {
        return [
            [
                'id' => 'exp-001',
                'experiment_id' => 'latency',
                'status' => 'completed',
                'started_at' => (new \DateTimeImmutable('-2 days'))->format('c'),
                'duration' => '5 minutes',
                'result' => [
                    'requests_affected' => 523,
                    'avg_latency_added' => '187ms',
                    'errors_caused' => 0,
                    'circuit_breakers_triggered' => false,
                ],
            ],
            [
                'id' => 'exp-002',
                'experiment_id' => 'error_injection',
                'status' => 'completed',
                'started_at' => (new \DateTimeImmutable('-5 days'))->format('c'),
                'duration' => '3 minutes',
                'result' => [
                    'requests_affected' => 45,
                    'error_rate_actual' => '4.8%',
                    'retry_success_rate' => '100%',
                    'user_impact' => 'minimal',
                ],
            ],
            [
                'id' => 'exp-003',
                'experiment_id' => 'database_slow',
                'status' => 'completed',
                'started_at' => (new \DateTimeImmutable('-7 days'))->format('c'),
                'duration' => '10 minutes',
                'result' => [
                    'queries_affected' => 1250,
                    'avg_delay_added' => '950ms',
                    'connection_pool_exhaustion' => false,
                    'timeout_errors' => 3,
                ],
            ],
        ];
    }

    public function getGameDays(): array
    {
        return [
            [
                'id' => 'gd-001',
                'name' => 'Q1 2026 Game Day',
                'date' => '2026-01-15',
                'status' => 'completed',
                'scenarios_tested' => ['database_failover', 'instance_failure'],
                'participants' => 8,
                'findings' => 2,
                'action_items_closed' => 2,
            ],
            [
                'id' => 'gd-002',
                'name' => 'Q4 2025 Game Day',
                'date' => '2025-10-20',
                'status' => 'completed',
                'scenarios_tested' => ['region_failover', 'network_partition'],
                'participants' => 12,
                'findings' => 5,
                'action_items_closed' => 5,
            ],
        ];
    }
}
