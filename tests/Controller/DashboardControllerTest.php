<?php

declare(strict_types=1);

namespace App\Tests\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class DashboardControllerTest extends WebTestCase
{
    public function testDashboardIndex(): void
    {
        $client = static::createClient();
        $client->request('GET', '/dashboard');

        $this->assertResponseIsSuccessful();
        $this->assertSelectorTextContains('h1', 'Dashboard');
    }

    public function testDeploymentsPage(): void
    {
        $client = static::createClient();
        $client->request('GET', '/dashboard/deployments');

        $this->assertResponseIsSuccessful();
    }

    public function testSecurityPage(): void
    {
        $client = static::createClient();
        $client->request('GET', '/dashboard/security');

        $this->assertResponseIsSuccessful();
    }
}
