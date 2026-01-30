<?php

declare(strict_types=1);

namespace App\Tests\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class HomeControllerTest extends WebTestCase
{
    public function testHomepage(): void
    {
        $client = static::createClient();
        $client->request('GET', '/');

        $this->assertResponseIsSuccessful();
        $this->assertSelectorTextContains('h1', 'Symfony AWS Platform');
    }

    public function testHealthEndpoint(): void
    {
        $client = static::createClient();
        $client->request('GET', '/health');

        $this->assertResponseIsSuccessful();
        
        $response = $client->getResponse();
        $data = json_decode($response->getContent(), true);
        
        $this->assertArrayHasKey('status', $data);
        $this->assertEquals('healthy', $data['status']);
    }

    public function testAboutPage(): void
    {
        $client = static::createClient();
        $client->request('GET', '/about');

        $this->assertResponseIsSuccessful();
        $this->assertSelectorTextContains('h1', 'About');
    }
}
