<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
?>

<?php slot::start('head') ?>
    <title>Crash Data for <?php out::H($product) ?> <?php out::H($version); ?></title>
<?php slot::end() ?>


<?php slot::start('head') ?>
    <title>Crash Data for <?php out::H($product) ?>
        <?php if (isset($version) && !empty($version)) { ?>
            <?php out::H($version); ?>
        <?php } ?>
    </title>
<?php slot::end() ?>


<?php
echo html::stylesheet(array(
		'css/daily.css',
	), array('screen', 'screen'));

View::factory('common/dashboard_product', array(
    'duration' => $duration,
    'graph_data' => $graph_data,
    'product' => $product,
    'top_crashers' => $top_crashers,
    'url_base' => $url_base,
    'version' => $version,
))->render(TRUE);

echo '<script>var data = ' . json_encode($graph_data) . '</script>';
echo html::script(array(
        'js/flot-0.7/jquery.flot.pack.js',
        'js/socorro/utils.js',
        'js/socorro/dashboard_graph.js',
        'js/socorro/daily.js',
    ));

?>