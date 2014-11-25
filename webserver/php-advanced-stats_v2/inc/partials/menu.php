<?php include("inc/config.inc.php") ?>
<!-- Navigation -->
<nav class="navbar navbar-default navbar-static-top" role="navigation" style="margin-bottom: 0">
    <div class="navbar-header">
        <a class="navbar-brand" href="index.php"><?php echo $name ?> - Timer Stats v2</a>
    </div>
    <ul class="nav navbar-top-links navbar-right">
        <li class="dropdown">
            <a class="dropdown-toggle" data-toggle="dropdown" href="#">
                About <i class="fa fa-caret-down"></i>
            </a>
            <ul class="dropdown-menu dropdown-messages">
                <li>
						<a href="http://github.com/Zipcore/Timer">Project Home</a>
						<a href="http://github.com/Zipcore/Timer/releases">Changelog</a>
						<a href="http://github.com/Zipcore/Timer/wiki">Wiki</a>
						<a href="http://github.com/Zipcore/Timer/issues/new">Report Bugs</a>
                </li>
                <li class="divider"></li>
                <li>
						<a><img src="img/zipcore.png"> Contact Zipcore:</a>
						<a href="http://forums.alliedmods.net/member.php?u=74431"><img src="img/am.png"> AlliedMods</a>
						<a href="http://github.com/Zipcore"><img src="img/github.png"> GitHub</a>
						<a href="http://http://steamcommunity.com/profiles/76561198035410392"><img src="img/steam.png"> Steam</a>
                </li>
            </ul>
            <!-- /.dropdown-messages -->
        </li>
    </ul>
    <!-- /.navbar-top-links -->

    <div class="navbar-default sidebar" role="navigation">
        <div class="sidebar-nav navbar-collapse">
            <ul class="nav" id="side-menu">
                <li class="sidebar-search">
                    <div class="input-group custom-search-form">
                        <input type="text" class="form-control" placeholder="Player Search...">
                        <span class="input-group-btn">
                        <button class="btn btn-default" type="button">
                            <i class="fa fa-search"></i>
                        </button>
                    </span>
                    </div>
                </li>
				<li>
					<a href="<?php echo $path_homepage?>"><?php echo $name_homepage?></a>
				</li>
				<li>
					<a href="index.php">Dashboard</a>
				</li>
				<li>
					<a href="index.php?site=status">Player/Server Status</a>
				</li>
                <li>
                    <a href="#">Top Players<span class="fa arrow"></span></a>
                    <ul class="nav nav-second-level">
                    <?php if ($module["points"]==true) { ?>
						<li>
							<a href="index.php?site=toppoints">by Points</a>
						</li>
                    <?php } ?>
						<li>
							<a href="index.php?site=topworldrecord">by World Records</a>
						</li>
                    </ul>
                </li>
				<li>
					<a href="index.php?site=maptop">Map Top</a>
				</li>
				<li>
					<a href="index.php?site=latest">Latest Records</a>
				</li>
				<li>
					<a href="index.php?site=maps">Map Info</a>
				</li>
				<li>
					<a href="index.php?site=ranks">Chatranks</a>
				</li>
            </ul>
        </div>
    </div>
</nav>
