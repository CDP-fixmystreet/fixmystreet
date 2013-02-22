use strict;
use warnings;
use Test::More;

use FixMyStreet::TestMech;

my $mech = FixMyStreet::TestMech->new;

my $dt = DateTime->new(
    year => 2011,
    month => 10,
    day     => 10
);

my $user1 = FixMyStreet::App->model('DB::User')
  ->find_or_create( { email => 'reporter-rss@example.com', name => 'Reporter User' } );

my $report = FixMyStreet::App->model('DB::Problem')->find_or_create( {
    postcode           => 'eh1 1BB',
    bodies_str         => '2651',
    areas              => ',11808,135007,14419,134935,2651,20728,',
    category           => 'Street lighting',
    title              => 'Testing',
    detail             => 'Testing Detail',
    used_map           => 1,
    name               => $user1->name,
    anonymous          => 0,
    state              => 'confirmed',
    confirmed          => $dt,
    lastupdate         => $dt,
    whensent           => $dt->clone->add( minutes => 5 ),
    lang               => 'en-gb',
    service            => '',
    cobrand            => 'default',
    cobrand_data       => '',
    send_questionnaire => 1,
    latitude           => '55.951963',
    longitude          => '-3.189944',
    user_id            => $user1->id,
} );


$mech->get_ok("/rss/pc/EH11BB/2");
$mech->content_contains( "Testing, 10th October" );
$mech->content_lacks( 'Nearest road to the pin' );

$report->geocode( 
{
          'traceId' => 'ae7c4880b70b423ebc8ab4d80961b3e9|LTSM001158|02.00.71.1600|LTSMSNVM002010, LTSMSNVM001477',
          'statusDescription' => 'OK',
          'brandLogoUri' => 'http://dev.virtualearth.net/Branding/logo_powered_by.png',
          'resourceSets' => [
                              {
                                'resources' => [
                                                 {
                                                   'geocodePoints' => [
                                                                        {
                                                                          'calculationMethod' => 'Interpolation',
                                                                          'coordinates' => [
                                                                                             '55.9532357007265',
                                                                                             '-3.18906001746655'
                                                                                           ],
                                                                          'usageTypes' => [
                                                                                            'Display',
                                                                                            'Route'
                                                                                          ],
                                                                          'type' => 'Point'
                                                                        }
                                                                      ],
                                                   'entityType' => 'Address',
                                                   'name' => '18 N Bridge, Edinburgh EH1 1',
                                                   'point' => {
                                                                'coordinates' => [
                                                                                   '55.9532357007265',
                                                                                   '-3.18906001746655'
                                                                                 ],
                                                                'type' => 'Point'
                                                              },
                                                   'bbox' => [
                                                               '55.9493729831558',
                                                               '-3.19825819222605',
                                                               '55.9570984182972',
                                                               '-3.17986184270704'
                                                             ],
                                                   'matchCodes' => [
                                                                     'Good'
                                                                   ],
                                                   'address' => {
                                                                  'countryRegion' => 'United Kingdom',
                                                                  'adminDistrict2' => 'Edinburgh City',
                                                                  'adminDistrict' => 'Scotland',
                                                                  'addressLine' => '18 North Bridge',
                                                                  'formattedAddress' => '18 N Bridge, Edinburgh EH1 1',
                                                                  'postalCode' => 'EH1 1',
                                                                  'locality' => 'Edinburgh'
                                                                },
                                                   'confidence' => 'Medium',
                                                   '__type' => 'Location:http://schemas.microsoft.com/search/local/ws/rest/v1'
                                                 }
                                               ],
                                'estimatedTotal' => 1
                              }
                            ],
          'copyright' => "Copyright \x{a9} 2011 Microsoft and its suppliers. All rights reserved. This API cannot be accessed and the content and any results may not be used, reproduced or transmitted in any manner without express written permission from Microsoft Corporation.",
          'statusCode' => 200,
          'authenticationResultCode' => 'ValidCredentials'
        }
);
$report->update();

$mech->get_ok("/rss/pc/EH11BB/2");
$mech->content_contains( "Testing, 10th October" );
$mech->content_contains( '18 North Bridge, Edinburgh' );

$report->delete();

my $now = DateTime->now();
my $report_to_council = FixMyStreet::App->model('DB::Problem')->find_or_create(
    {
        postcode           => 'WS13 6YY',
        bodies_str         => '2434',
        areas              => ',2434,2240,',
        category           => 'Other',
        title              => 'council report',
        detail             => 'Test 2 Detail',
        used_map           => 't',
        name               => 'Test User',
        anonymous          => 'f',
        state              => 'closed',
        confirmed          => $now->ymd . ' ' . $now->hms,
        lang               => 'en-gb',
        service            => '',
        cobrand            => 'default',
        cobrand_data       => '',
        send_questionnaire => 't',
        latitude           => '52.727588',
        longitude          => '-1.731322',
        user_id            => $user1->id,
    }
);

my $report_to_county_council = FixMyStreet::App->model('DB::Problem')->find_or_create(
    {
        postcode           => 'WS13 6YY',
        bodies_str         => '2240',
        areas              => ',2434,2240,',
        category           => 'Other',
        title              => 'county report',
        detail             => 'Test 2 Detail',
        used_map           => 't',
        name               => 'Test User',
        anonymous          => 'f',
        state              => 'closed',
        confirmed          => $now->ymd . ' ' . $now->hms,
        lang               => 'en-gb',
        service            => '',
        cobrand            => 'default',
        cobrand_data       => '',
        send_questionnaire => 't',
        latitude           => '52.727588',
        longitude          => '-1.731322',
        user_id            => $user1->id,
    }
);

subtest "check RSS feeds on cobrand have correct URLs for non-cobrand reports" => sub {
    $mech->host('lichfielddc.fixmystreet.com');
    $mech->get_ok("/rss/area/Lichfield");

    my $expected1 = mySociety::Config::get('BASE_URL') . '/report/' . $report_to_county_council->id;
    my $cobrand = FixMyStreet::Cobrand->get_class_for_moniker('lichfielddc')->new();
    my $expected2 = $cobrand->base_url . '/report/' . $report_to_council->id;

    $mech->content_contains($expected1, 'non cobrand area report point to fixmystreet.com');
    $mech->content_contains($expected2, 'cobrand area report point to cobrand url');
};

$mech->delete_user( $user1 );

done_testing();
