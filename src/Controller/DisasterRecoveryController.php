<?php

declare(strict_types=1);

namespace App\Controller;

use App\Service\DisasterRecoveryService;
use App\Service\ChaosEngineeringService;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/disaster-recovery', name: 'dr_')]
class DisasterRecoveryController extends AbstractController
{
    public function __construct(
        private readonly DisasterRecoveryService $drService,
        private readonly ChaosEngineeringService $chaosService,
    ) {
    }

    #[Route('', name: 'index')]
    public function index(): Response
    {
        return $this->render('disaster_recovery/index.html.twig', [
            'status' => $this->drService->getStatus(),
            'scenarios' => $this->drService->getScenarios(),
            'history' => $this->drService->getSimulationHistory(),
            'healthChecks' => $this->drService->getHealthChecks(),
        ]);
    }

    #[Route('/simulations', name: 'simulations')]
    public function simulations(): Response
    {
        return $this->render('disaster_recovery/simulations.html.twig', [
            'scenarios' => $this->drService->getScenarios(),
            'history' => $this->drService->getSimulationHistory(),
        ]);
    }

    #[Route('/chaos', name: 'chaos')]
    public function chaos(): Response
    {
        return $this->render('disaster_recovery/chaos.html.twig', [
            'enabled' => $this->chaosService->isEnabled(),
            'experiments' => $this->chaosService->getExperiments(),
            'activeExperiments' => $this->chaosService->getActiveExperiments(),
            'history' => $this->chaosService->getExperimentHistory(),
            'gameDays' => $this->chaosService->getGameDays(),
        ]);
    }

    #[Route('/runbooks', name: 'runbooks')]
    public function runbooks(): Response
    {
        return $this->render('disaster_recovery/runbooks.html.twig', [
            'runbooks' => $this->getRunbooks(),
        ]);
    }

    #[Route('/api/status', name: 'api_status', methods: ['GET'])]
    public function apiStatus(): JsonResponse
    {
        return $this->json($this->drService->getStatus());
    }

    #[Route('/api/simulate', name: 'api_simulate', methods: ['POST'])]
    public function apiSimulate(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);
        $scenarioId = $data['scenario'] ?? null;
        $dryRun = $data['dry_run'] ?? true;

        if (!$scenarioId) {
            return $this->json(['error' => 'Scenario ID is required'], Response::HTTP_BAD_REQUEST);
        }

        try {
            $result = $this->drService->runSimulation($scenarioId, ['dry_run' => $dryRun]);
            return $this->json($result);
        } catch (\InvalidArgumentException $e) {
            return $this->json(['error' => $e->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    #[Route('/api/chaos/start', name: 'api_chaos_start', methods: ['POST'])]
    public function apiChaosStart(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);
        $experimentId = $data['experiment'] ?? null;
        $parameters = $data['parameters'] ?? [];

        if (!$experimentId) {
            return $this->json(['error' => 'Experiment ID is required'], Response::HTTP_BAD_REQUEST);
        }

        try {
            $result = $this->chaosService->startExperiment($experimentId, $parameters);
            return $this->json($result);
        } catch (\Exception $e) {
            return $this->json(['error' => $e->getMessage()], Response::HTTP_BAD_REQUEST);
        }
    }

    #[Route('/api/chaos/stop/{runId}', name: 'api_chaos_stop', methods: ['POST'])]
    public function apiChaosStop(string $runId): JsonResponse
    {
        $result = $this->chaosService->stopExperiment($runId);
        return $this->json($result);
    }

    #[Route('/api/health-checks', name: 'api_health_checks', methods: ['GET'])]
    public function apiHealthChecks(): JsonResponse
    {
        return $this->json($this->drService->getHealthChecks());
    }

    private function getRunbooks(): array
    {
        return [
            [
                'id' => 'rb-001',
                'name' => 'Database Failover Runbook',
                'category' => 'database',
                'severity' => 'P1',
                'last_updated' => '2026-01-15',
                'estimated_time' => '10 minutes',
                'steps' => [
                    'Verify primary database failure',
                    'Check replica sync status',
                    'Promote read replica: aws rds promote-read-replica',
                    'Update application config',
                    'Verify new primary connectivity',
                    'Update monitoring alerts',
                    'Notify stakeholders',
                ],
            ],
            [
                'id' => 'rb-002',
                'name' => 'Region Failover Runbook',
                'category' => 'infrastructure',
                'severity' => 'P1',
                'last_updated' => '2026-01-10',
                'estimated_time' => '15 minutes',
                'steps' => [
                    'Confirm primary region failure',
                    'Activate DR region Terraform',
                    'Promote database replica',
                    'Update Route 53 weights',
                    'Verify DR application health',
                    'Monitor traffic shift',
                    'Update status page',
                    'Post-incident communication',
                ],
            ],
            [
                'id' => 'rb-003',
                'name' => 'Blue/Green Rollback Runbook',
                'category' => 'deployment',
                'severity' => 'P2',
                'last_updated' => '2026-01-20',
                'estimated_time' => '5 minutes',
                'steps' => [
                    'Identify deployment issue',
                    'Run rollback script: ./scripts/rollback.sh',
                    'Verify traffic switch',
                    'Check application health',
                    'Review error logs',
                    'Create incident ticket',
                ],
            ],
            [
                'id' => 'rb-004',
                'name' => 'Security Incident Response',
                'category' => 'security',
                'severity' => 'P1',
                'last_updated' => '2026-01-25',
                'estimated_time' => '30 minutes',
                'steps' => [
                    'Isolate affected systems',
                    'Preserve evidence',
                    'Assess impact scope',
                    'Notify security team',
                    'Apply emergency patches',
                    'Rotate credentials',
                    'Monitor for continued activity',
                    'Document timeline',
                ],
            ],
            [
                'id' => 'rb-005',
                'name' => 'Cache Layer Recovery',
                'category' => 'cache',
                'severity' => 'P2',
                'last_updated' => '2026-01-18',
                'estimated_time' => '10 minutes',
                'steps' => [
                    'Verify cache cluster status',
                    'Check application fallback mode',
                    'Restart cache nodes if needed',
                    'Initiate cache warming',
                    'Monitor database load',
                    'Verify cache hit rates',
                ],
            ],
        ];
    }
}
