<?php
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
?>
<div class='correlation'><h3><?= html::specialchars($details['crash_reason'])?> (<?= $details['count'] ?>)</h3>
<pre><?= join("\n", $details['correlations']) ?></pre></div>