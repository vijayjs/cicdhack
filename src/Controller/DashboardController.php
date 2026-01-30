<?php

declare(strict_types=1);

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/dashboard', name: 'dashboard_')]
class DashboardController extends AbstractController
{
    #[Route('', name: 'index')]
    public function index(): Response
    {
        return $this->render('dashboard/index.html.twig', [
            'deployments' => $this->getRecentDeployments(),
            'metrics' => $this->getMetrics(),
            'blueGreen' => $this->getBlueGreenStatus(),
        ]);
    }

    #[Route('/deployments', name: 'deployments')]
    public function deployments(): Response
    {
        return $this->render('dashboard/deployments.html.twig', [
            'deployments' => $this->getRecentDeployments(),
            'blueGreen' => $this->getBlueGreenStatus(),
        ]);
    }

    #[Route('/security', name: 'security')]
    public function security(): Response
    {
        return $this->render('dashboard/security.html.twig', [
            'scans' => $this->getSecurityScans(),
        ]);
    }

    private function getRecentDeployments(): array
    {
        return [
            ['version' => 'v1.3.0', 'env' => 'blue', 'status' => 'active', 'date' => '2026-01-30'],
            ['version' => 'v1.2.0', 'env' => 'green', 'status' => 'standby', 'date' => '2026-01-28'],
            ['version' => 'v1.1.0', 'env' => 'blue', 'status' => 'archived', 'date' => '2026-01-25'],
        ];
    }

    private function getMetrics(): array
    {
        return [
            'lead_time' => ['value' => '4.2h', 'trend' => 'down'],
            'deploy_freq' => ['value' => '8/week', 'trend' => 'up'],
            'mttr' => ['value' => '12min', 'trend' => 'down'],
            'failure_rate' => ['value' => '2.1%', 'trend' => 'down'],
        ];
    }

    private function getBlueGreenStatus(): array
    {
        return [
            'active' => $_ENV['DEPLOYMENT_ENV'] ?? 'blue',
            'blue' => ['version' => 'v1.3.0', 'status' => 'healthy', 'traffic' => 100],
            'green' => ['version' => 'v1.2.0', 'status' => 'healthy', 'traffic' => 0],
        ];
    }

    private function getSecurityScans(): array
    {
        return [
            ['type' => 'SAST', 'tool' => 'PHPStan', 'status' => 'passed', 'issues' => 0],
            ['type' => 'SCA', 'tool' => 'Composer Audit', 'status' => 'passed', 'issues' => 1],
            ['type' => 'Container', 'tool' => 'Trivy', 'status' => 'passed', 'issues' => 2],
            ['type' => 'IaC', 'tool' => 'tfsec', 'status' => 'passed', 'issues' => 0],
        ];
    }
}
