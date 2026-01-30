<?php

declare(strict_types=1);

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class HomeController extends AbstractController
{
    #[Route('/', name: 'app_home')]
    public function index(): Response
    {
        return $this->render('home/index.html.twig', [
            'environment' => $_ENV['DEPLOYMENT_ENV'] ?? 'blue',
            'version' => $_ENV['APP_VERSION'] ?? '1.0.0',
            'serverInfo' => [
                'hostname' => gethostname(),
                'php_version' => PHP_VERSION,
                'symfony_version' => \Symfony\Component\HttpKernel\Kernel::VERSION,
            ],
        ]);
    }

    #[Route('/health', name: 'app_health')]
    public function health(): Response
    {
        return $this->json([
            'status' => 'healthy',
            'timestamp' => (new \DateTimeImmutable())->format('c'),
            'environment' => $_ENV['DEPLOYMENT_ENV'] ?? 'blue',
            'version' => $_ENV['APP_VERSION'] ?? '1.0.0',
        ]);
    }

    #[Route('/about', name: 'app_about')]
    public function about(): Response
    {
        return $this->render('home/about.html.twig', [
            'features' => [
                'Blue/Green Deployment' => 'Zero-downtime releases with instant rollback',
                'AWS Free Tier' => 'Cost-effective infrastructure on EC2 t2.micro',
                'CI/CD Pipeline' => 'Automated testing and deployment with GitHub Actions',
                'Security Scanning' => 'SAST, dependency, and container vulnerability scanning',
                'Infrastructure as Code' => 'Complete Terraform automation',
            ],
        ]);
    }
}
