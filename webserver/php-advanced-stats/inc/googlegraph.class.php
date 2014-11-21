<?php
	/*
		Name: GoogleGraph Class
		Version: 2.1
		Updated: 5/5/08
		Description: A class to dynamically generate graphs from Google
		Author: Ryon Sherman
		Time: 12 hrs and 4 pots of coffee
		Note: If I messed something up, forgive me, I'm no professional.			
		Also, the code preview throws my tabs all out of whack.
		It looks good in my IDE, I swear!	
	*/
	
	class Data {
		/*
			Description: Data object
			Methods:
				'setEncoding'	=	Sets the data encoding scheme					
				'addData'			=	Adds a unit of data to the graph
			Important Variables:
				'data'				=	Data fed to the graph							
		*/
		var $encoding = 'text';
		var $data = array();
		var $scale = array();
		
		public function setEncoding($encoding = null) {
			/*
				Description: Sets the data encoding scheme
				Usage: $graph->Graph->setEncoding('text');
				Note: When using different encoding schemes the maximum value varies, 
					changing the scale of the graph.
				Arguments:
					'text'			=	Plain text encoding
					'simple'		=	Simple single character encoding
					'extended'	=	Extended double character encoding
			*/
			if(!empty($encoding)) {
				$this->encoding = $encoding;
			}
		}
		
		public function setScale($scale = array()) {
			/*
				Description: Specify the data scaling
				Usage: $graph->Graph->setDataScale(array('data set 1 min', 'data set 1 max', 'data set n min', 'data set n max' etc);
				Arguments:
					'scale'	= The first value is the min for the first 1st data, etc.
			*/
			if(!empty($scale)) {
				$this->scale = $scale;
			}
		}
		
		public function addData($data = array()) {
			/*
				Description: Adds a unit of data to the graph
				Usage: $graph->Graph->addData(array('data', 'data', 'data', etc...);				
				Arguments:
					'data'
						'text'			=	Supports floating point numbers from zero (0.0) to 100.0
						'simple'		=	Supports integer numbers from 0 to 61
						'extended'	=	Supports integer numbers from 0 to 4095	
			*/
			if(!empty($data)) {									
				$this->data[] = $data;				
			}			
		}
	}
	
	class Graph {		
		/*
			Description: Graph object
			Methods:
				'Graph'						=	Initializes object
				'setType'						=	Set the chart Type
				'setSubtype'					=	Set the chart Subtype
				'addShapeMarker'			=	Specify shape markers for points on line charts and scatter plots
				'setTitle'						=	Specify a chart title
				'setSize'						=	Specify chart size
				'addLineStyle'				=	Specify chart line styles
				'setAxisRange'				=	Specify a range
				'setGridLines'				=	Specify a chart grid
				'setLegend'					=	Specify a legend for a chart
				'addAxisLabel'				=	Specify Axis labels
				'addPieLabel'				=	Specify Pie labels
				'addAxisStyle'				=	Specify font size, color, and alignment for axis labels
				'addLabelPosition'			=	Specify label positions
				'setLineColors'				=	Specify colors for lines, bars, Venn diagrams, and pie segments
				'setBarSize'					=	Specify bar thickness
				'addFill'						=	Specify background fill or chart area
			Important Variables:
				'FILL_PATTERNS'			=	Currently supported fill patterns
				'TYPES'						=	Currently supported graph types
				'LINE_SUBTYPES'			=	Currently supported line graph types
				'BAR_SUBTYPES'			=	Currently supported bar graph types
				'PIE_SUBTYPES'			=	Currently supported pie graph types
				'VENN_SUBTYPES'			=	Currently supported venn graph types
				'SCATTER_SUBTYPES'	=	Currently supported scatter graph types
		*/
		var $FILL_PATTERNS = array('solid', 'gradient', 'stripes');
		var $TYPES = array('line', 'bar', 'pie', 'venn', 'scatter');
		var $LINE_SUBTYPES = array('chart', 'axis');			
		var $BAR_SUBTYPES = array('horizontal_stacked', 'vertical_stacked', 'horizontal_grouped', 'vertical_grouped');
		var $PIE_SUBTYPES = array('2d', '3d');
		var $VENN_SUBTYPES = array('venn');
		var $SCATTER_SUBTYPES = array('scatter');
		
		var $type = 'line';
		var $subtype = 'chart';		
		var $title = null;
		var $title_color = null;
		var $title_size = null;
		var $legend = array();
		var $line_colors = array();
		var $bar_size = null;
		var $chart_colors = array();
		var $chart_size = '300x300';
		var $axis = null;
		var $axis_labels = array();
		var $pie_labels = array();
		var $label_positions = array();
		var $axis_ranges = array();
		var $axis_styles = array();
		var $line_styles = array();
		var $grid_lines = null;
		var $markers = array();		
		
		public function setType($type = null) {
			/* 
				Description: Set the chart Type
				Usage: $graph->Graph->setType('type');
				Arguments:
					'line'		=	A line chart, data points are spaced evenly along the x-axis.
									Provide a pair of data sets for each line you wish to draw, 
									the first data set of each pair specifies the x-axis coordinates, the second the y-axis coordinates.
					'bar'		=	Horizontal and vertical bar chart respectively.
									Horizontal and vertical bar chart, respectively, in specified colors; multiple data sets are grouped.
									Bar chart size is handled in a different way than for other chart types.
					'pie'		=	Two dimensional pie chart.
									Three dimensional pie chart.
					'venn'	=	
					'scatter'	=	Supply two data sets, the first data set specifies x coordinates, the second set specifies y coordinates.
			*/
			if(@in_array(strtolower($type), $this->TYPES)) {
				$this->type = strtolower($type);
				
				switch(strtolower($type)) {
					case 'line':
						$this->subtype = 'chart';
						break;
					case 'bar':
						$this->subtype = 'horizontal_grouped';
						break;
					case 'pie':
						$this->subtype = '2d';
						break;
					case 'venn':
						$this->subtype = 'venn';
						break;
					case 'scatter':
						$this->subtype = 'scatter';
						break;
				}
			}
		}
		
		public function setSubtype($subtype = null) {
			/*
				Description: Set the chart Subtype
				Usage: $graph->Graph->setSubtype('subtype');
				Arguments:
					'line'
						'chart'						=	A line chart, data points are spaced evenly along the x-axis.
						'axis'							=	Provide a pair of data sets for each line you wish to draw, 
															the first data set of each pair specifies the x-axis coordinates, the second the y-axis coordinates.
					'bar'
						'horizontal_stacked'	
						'vertical_stacked'		=	Horizontal and vertical bar chart respectively.
						'horizontal_grouped'		=	Bar chart size is handled in a different way than for other chart types.					
						'vertical_grouped'		=	Horizontal and vertical bar chart, respectively, in specified colors; multiple data sets are grouped.
					'pie'
						'2d'							=	Two dimensional pie chart.
						'3d'							=	Three dimensional pie chart.
					'venn'
					'scatter'							=	Supply two data sets, the first data set specifies x coordinates, the second set specifies y coordinates.						
			*/
			switch($this->type) {
				case 'line':
					$subtypes = $this->LINE_SUBTYPES;							
					break;
				case 'bar':
					$subtypes = $this->BAR_SUBTYPES;					
					break;
				case 'pie':
					$subtypes = $this->PIE_SUBTYPES;
					break;
				case 'venn':
					$subtypes = $this->VENN_SUBTYPES;
					break;
				case 'scatter':
					$subtypes = $this->SCATTER_SUBTYPES;
					break;
				default:
					break;
			}
			if(in_array(strtolower($subtype), $subtypes))
				$this->subtype = strtolower($subtype);
		}
		
		public function addShapeMarker($markers = array()) {
			/*
				Description: Specify shape markers for points on line charts and scatter plots
				Usage: $graph->Graph->addShapeMarker(array('shape', 'color', 'data set index', 'data point', 'size'));
				Arguments:
					'shape'
						'arrow'						=	represents an arrow.
						'cross'						=	represents a cross.
						'diamond'						=	represents a diamond.
						'circle'						=	represents a circle.
						'square'						=	represents a square.
						'small_vertical_line' 		=	represents a vertical line from the x-axis to the data point.
						'big_vertical_line'			=	represents a vertical line to the top of the chart.
						'horizontal_line'				=	represents a horizontal line across the chart.
						'x'								=	represents an x shape.
					'color'							=	Values are RRGGBB format hexadecimal numbers.
					'data set index'				=	the index of the line on which to draw the marker. This is 0 for the first data set, 1 for the second and so on.
					'data point'						=	Is a floating point value that specifies on which data point the marker will be drawn. 
															This is 1 for the first data set, 2 for the second and so on. Specify a fraction to interpolate a marker between two points.
					'size'								=	is the size of the marker in pixels.
			*/
			if(!empty($markers)) {
				switch(strtolower($markers[0])) {
					case 'arrow':
						$markers[0] = 'a';
						$this->markers[] = $markers;
						break;
					case 'cross':
						$markers[0] = 'c';
						$this->markers[] = $markers;
						break;
					case 'diamond':
						$markers[0] = 'd';
						$this->markers[] = $markers;
						break;
					case 'circle':
						$markers[0] = 'o';
						$this->markers[] = $markers;
						break;
					case 'x':
						$markers[0] = 'x';
						$this->markers[] = $markers;
						break;
					case 'square':
						$markers[0] = 's';
						$this->markers[] = $markers;
						break;
					case 'small_vertical_line':					
						$markers[0] ='v';
						$this->markers[] = $markers;
						break;
					case 'big_vertical_line':					
						$markers[0] = 'V';
						$this->markers[] = $markers;
						break;
					case 'horizontal_line':						
						$markers[0] = 'h';
						$this->markers[] = $markers;
						break;
					case 'horizontal_range':
						$markers[0] = 'r';
						$this->markers[] = $markers;
						break;
					case 'vertical_range':
						$markers[0] = 'R';
						$this->markers[] = $markers;
					default:						
						break;
				}
			}
		}
		
		public function setTitle($title, $color = null, $size = null) {
			/*
				Description: Specify a chart title
				Usage: $graph->Graph->setTitle('title', 'color', 'size');
				Arguments:
					'title'					=	Use a pipe character (|) to force a line break.
					'color'				=	Values are RRGGBB format hexadecimal numbers.
					'size'					=	Font size
			*/
			$this->title = str_replace(' ', '+', $title); //Replaces spaces with '+', use '|' for line breaks
			if(!empty($color))
				$this->title_color = str_replace('#', '', $color); //Strips '#' off color value
			if(!empty($size))
				$this->title_size = intval($size);
		}
		
		public function setSize($width = null, $height = null) {
			/*
				Description: Specify chart size
				Usage: $graph->Graph->setSize('width', 'height');
				Note: The largest possible area for a chart is 300,000 pixels. As the maximum height or width is 1000 pixels, 
						examples of maximum sizes are 1000x300, 300x1000, 600x500, 500x600, 800x375, and 375x800.
				Arguments:
					'width'			=	Size in pixels
					'height'			=	Size in pixels
			*/
			if(!empty($width) AND !empty($height)) {
				$this->chart_size = intval($width).'x'.intval($height);
			}
		}
		
		public function addLineStyle($line_styles = array()) {
			/*
				Description: Specify chart line styles
				Usage: $graph->Graph->addLineStyle(array('line thickness', 'length of line', 'length of blank'));
				Notes:	Parameter values are floating point numbers, multiple line styles are separated by the pipe character (|). 
							The first line style is applied to the first data set, the second style to the second data set, and so on.
			*/
			if(!empty($line_styles)) 
				$this->line_styles[] = $line_styles;
		}
		
		public function setAxisRange($ranges = array()) {
			/*
				Description: Specify a range
				Usage: $graph->Graph->setAxisRange(array('axis index', 'start of range', 'end of range'));				
			*/
			if(!empty($ranges)) 
				$this->axis_ranges = $ranges;			
		}
		
		public function setGridLines($x = 0, $y = 0, $line = 0, $blank = 0) {
			/*
				Description: Specify a chart grid
				Usage: $graph->Graph->setGridLines('x axis', 'y axis', 'length of line', 'length of blank');
				Notes: Parameter values can be integers or have a single decimal place - 10.0 or 10.5 for example.
			*/
			$this->grid_lines = null;
			if(!is_null($x)) $this->grid_lines .= $x.',';
			if(!is_null($y)) $this->grid_lines .= $y.',';
			if(!is_null($line)) $this->grid_lines .= $line.',';
			if(!is_null($blank)) $this->grid_lines .= $blank.',';
			$this->grid_lines = substr($this->grid_lines, 0, -1);
		}
		
		public function setLegend($legend = array()) {
			/*
				Description: Specify a legend for a chart
				Usage: $graph->Graph->setLegend(array('label', 'label', 'label', etc...));				
			*/
			$this->legend = $legend;			
		}
		
		public function addPieLabel($pie_labels = array()) {
			/*
				Description: Specify Pie labels
				Usage: $graph->Graph->addAxisLabel(array('label', 'label', 'label', etc...));
				Arguments:
					'label'				=	Label order corresponds with data order.
			*/
			if(!empty($pie_labels))
				$this->pie_labels = $pie_labels;
		}
		
		public function addAxisLabel($axis_labels = array()) {			
			/*
				Description: Specify Axis labels
				Usage: $graph->Graph->addAxisLabel(array('label', 'label', 'label', etc...));
				Arguments:
					'label'				=	The first label is placed at the start, the last at the end, others are uniformly spaced in between.
			*/
			if(!empty($axis_labels))
				$this->axis_labels[] = $axis_labels;
		}
		
		public function addAxisStyle($axis_styles = array()) {
			/*
				Description: Specify font size, color, and alignment for axis labels
				Usage: $graph->Graph->addAxisStyle(array('axis index', 'color', ['font size'], ['alignment']));
				Arguments:
					'axis index'			=	the axis index as specified
					'color'					=	the axis index as specified
					'font size'				=	is optional. If used this specifies the size in pixels.
					'alignment				=	is optional. By default: x-axis labels are centered, 
													left y-axis labels are right aligned, right y-axis labels are left aligned. 
													To specify alignment, use 0 for centered, -1 for left aligned, and 1 for right aligned.
			*/
			if(!empty($axis_styles))
				$this->axis_styles[] = $axis_styles;
		}
		
		public function setAxis($axes = array()) {			
			/*
				Description: Specify multiple axes
				Usage: $graph->Graph->setAxis(['bottom x-axis'], ['top x-axis'], ['left y-axis'], ['right y-axis']);
				Notes: Axes are specified by the index they have in the chxt parameter specification. 
							The first axis has an index of 0, the second has an index of 1, and so on. You can specify multiple axes by including x, t, y, or r multiple times.
			*/
			if(!empty($axes)) {
				$this->axis = null;
				foreach($axes as $axis) {
					$this->axis .= $axis.',';
				}
				$this->axis = substr($this->axis, 0, -1);				
			} else 
				$this->axis = 'x,t,y,r';			
		}
		
		public function addLabelPosition($label_positions = array()) {
			/*
				Description: Specify label positions
				Usage: $graph->Graph->addLabelPosition(array('position', 'position', 'position', etc...));
				Arguments:
					'position'				=	Use floating point numbers for position values.
			*/
			if(!empty($label_positions))
				$this->label_positions[] = $label_positions;
		}
		
		public function setLineColors($line_colors = array()) {
			/*
				Description: Specify colors for lines, bars, Venn diagrams, and pie segments
				Usage: $graph->Graph->setLineColors(array('color', 'color', 'color', etc...));
				Arguments:
					'color'	=	Values are RRGGBB format hexadecimal numbers.
			*/
			$colors = array();
			foreach($line_colors as $color) {
				$colors[] = str_replace('#', '', $color);
			}
			$this->line_colors = $colors;
		}
		
		public function setBarSize($size = null) {
			/*
				Description: Specify bar thickness
				Usage: $graph->Graph->setBarSize('size');
				Arguments:
					'size'			=	Integer
			*/
			$this->bar_size = intval($size);
		}
		
		public function addFill($area, $color, $pattern, $color2 = null, $angle = null, $var1 = null, $var2 = null ) {					
			/*
				Description: Specify background fill or chart area
				Usage: $graph->Graph->addFill('area', 'color', 'pattern', ['color2'], ['angle'], ['var1'], ['var2']);
				Arguments:
					'area'
						'background'	=	Background fill area.
						'chart'			=	Chart fill area.
					''color'				=	Values are RRGGBB format hexadecimal numbers.
					'pattern'
						'solid'			=	Solid fill
						'gradient'		=	Gradient fill
						'stripes'			=	Striped fill
					'color2'				=	Values are RRGGBB format hexadecimal numbers.
					'angle'				=	Specifies the angle of the gradient between 0 (horizontal) and 90 (vertical).
					'var1'
						'offset'			=	specify at what point the color is pure where: 0 specifies the right-most chart position and 1 the left-most.
						'width'			= 	must be between 0 and 1 where 1 is the full width of the chart. Stripes are repeated until the chart is filled.
					'var2'
						'offset1'		=	specify at what point the color is pure where: 0 specifies the right-most chart position and 1 the left-most.
						'width'			=	must be between 0 and 1 where 1 is the full width of the chart. Stripes are repeated until the chart is filled.					
			*/
			switch(strtolower($area)) {
				case 'background':
					$this->chart_colors['background']['color'] = str_replace('#', '', $color);
					if(in_array(strtolower($pattern), $this->FILL_PATTERNS)) {						
						if(strtolower($pattern) == 'gradient') {
							$this->chart_colors['background']['pattern'] = strtolower($pattern);
							$this->chart_colors['background']['angle'] = $angle;
							$this->chart_colors['background']['color2'] = str_replace('#', '', $color2);
							$this->chart_colors['background']['offset'] = $var1;
							$this->chart_colors['background']['offset2'] = $var2;
						} elseif(strtolower($pattern) == 'stripes') {
							$this->chart_colors['background']['pattern'] = strtolower($pattern);
							$this->chart_colors['background']['angle'] = $angle;
							$this->chart_colors['background']['color2'] = str_replace('#', '', $color2);
							$this->chart_colors['background']['width'] = $var1;
							$this->chart_colors['background']['width2'] = $var2;
						} else							
						$this->chart_colors['background']['pattern'] = strtolower($pattern);
					} else
						$this->chart_colors['background']['pattern'] = 'solid';
					break;
				case 'chart':
					$this->chart_colors['chart']['color'] = str_replace('#', '', $color);
					if(in_array(strtolower($pattern), $this->FILL_PATTERNS)) {						
						if(strtolower($pattern) == 'gradient') {
							$this->chart_colors['chart']['pattern'] = strtolower($pattern);
							$this->chart_colors['chart']['angle'] = $angle;
							$this->chart_colors['chart']['color2'] = str_replace('#', '', $color2);
							$this->chart_colors['chart']['offset'] = $var1;
							$this->chart_colors['chart']['offset2'] = $var2;
						} elseif(strtolower($pattern) == 'stripes') {
							$this->chart_colors['chart']['pattern'] = strtolower($pattern);
							$this->chart_colors['chart']['angle'] = $angle;
							$this->chart_colors['chart']['color2'] = str_replace('#', '', $color2);
							$this->chart_colors['chart']['width'] = $var1;
							$this->chart_colors['chart']['width2'] = $var2;
						} else
							$this->chart_colors['chart']['pattern'] = strtolower($pattern);
					} else
						$this->chart_colors['chart']['pattern'] = 'solid';
					break;						
			}
		}
	}
	
	class GoogleGraph {
		/*
			Description: Main object
			Usage: $graph = new GoogleGraph();
			Methods:
				'GoogleGraph'		=	Initializes object
				'printGraph'			=	Output graph
			Important Variables:
				'Graph'					=	Graph object
				'Data'					=	Data object
		*/
		var $BASE_ADDRESS = "http://chart.apis.google.com/chart?";
		
		var $Graph = null;
		var $Data = null;
		var $url = null;
		
		public function GoogleGraph() {
			/*
				Description: Initializes object
				Important Variables:
					'Graph'				=	Create Graph object
					'Data'				=	Create Data object
			*/
			$this->Graph = new Graph();
			$this->Data = new Data();
		}
		
		public function printGraph() {
			/*
				Description: Output graph
				Usage: $graph->Graph->printGraph();
			*/
			$url = $this->BASE_ADDRESS;
			
			$url .= 'cht=';
			switch($this->Graph->type) {
				case 'line':
					$url .= 'l';
					break;
				case 'bar':
					$url .= 'b';
					break;
				case 'pie':
					$url .= 'p';
					break;
				case 'venn':
					$url .= 'v';
					break;
				case 'scatter':
					$url .= 's';
					break;
			}
			switch($this->Graph->subtype) {
				case 'chart':
					$url .= 'c&';
					break;
				case 'axis':
					$url .= 'xy&';
					break;
				case 'horizontal_stacked':
					$url .= 'hs&';
					break;
				case 'vertical_stacked':
					$url .= 'vs&';
					break;
				case 'horizontal_grouped':
					$url .= 'hg&';
					break;
				case 'vertical_grouped':
					$url .= 'vg&';
					break;
				case '2d':
					$url .= '&';
					break;
				case '3d':
					$url .= '3&';
					break;
				case 'venn':
					$url .= '&';
					break;
				case 'scatter':
					$url .= '&';
					break;
			}			
			if(!empty($this->Graph->title))
				$url .= 'chtt='.$this->Graph->title.'&';
			if(!empty($this->Graph->title_color) AND !empty($this->Graph->title_size))
				$url .= 'chts='.$this->Graph->title_color.','.$this->Graph->title_size.'&';
			else if(!empty($this->Graph->title))
				$url .= 'chts='.$this->Graph->title.'&';
			if(!empty($this->Graph->legend)) 	
				$url .= 'chdl='.implode('|', $this->Graph->legend).'&';
			if(!empty($this->Graph->line_colors))
				$url .= 'chco='.implode(',', $this->Graph->line_colors).'&';
			if(!empty($this->Graph->bar_size))
				$url .= 'chbh='.intval($this->Graph->bar_size);
			if(!empty($this->Graph->chart_colors)) {				
				$url .= 'chf=';				
				foreach($this->Graph->chart_colors as $key => $value) {
					switch($key) {
						case 'background':
							$url .= 'bg,';
							break;
						case 'chart':
							$url .= 'c,';
							break;
					}					
					switch($value['pattern']) {
						case 'solid':
							$url .= 's,'.$value['color'].'|';
							break;
						case 'gradient':							
							$url .= 'lg,'.$value['angle'].','.$value['color'].','.$value['offset'].','.$value['color2'].','.$value['offset2'].'|';						
							break;
						case 'stripes':
							$url .= 'ls,'.$value['angle'].','.$value['color'].','.$value['width'].','.$value['color2'].','.$value['width2'].'|';
							break;
					}					
				}
				$url = substr($url, 0, -1);
				$url .= '&';
			}
			if(!empty($this->Graph->chart_size)) {
				$url .= 'chs='.$this->Graph->chart_size.'&';
			}
			if(!empty($this->Data->scale)) {
				$url .= 'chds=';
				$url .= implode(',', $this->Data->scale);
				$url .= '&';
			}
			if(!empty($this->Data->data)) {
				switch($this->Data->encoding) {					
					case 'simple':			
						$mapping = array_merge(range('A','Z'), range('a', 'z'), range('0', '9'));
						$url .= 'chd=s:';																		
						foreach($this->Data->data as $data) {
							$data_set = null;							
							foreach($data as $datum) {								
								if($datum === 'empty')									
									$data_set .= '_';
								else if(empty($datum) OR !in_array($datum, array_keys($mapping)))
									$data_set .= $mapping[0];
								else
									$data_set .= $mapping[$datum];								
							}
							$url .= $data_set.',';
						}
						$url = substr($url, 0, -1);
						$url .= '&';						
						break;
					case 'text':
						$url .= 'chd=t:';
						foreach($this->Data->data as $data) {							
							foreach($data as $datum) {
								$url .= number_format(intval($datum), 1, '.', '').',';
							}
							$url = substr($url, 0, -1);
							$url.= '|';
						}
						$url = substr($url, 0, -1);
						$url .= '&';
						break;
					case 'extended':
						$mapping = array_flip(array_merge(range('A','Z'), range('a', 'z'), range(0, 9), array('-', '.')));
						foreach(array_keys($mapping) as $key) {
							$mapping[$key] = array_flip(array_merge(range('A','Z'), range('a', 'z'), range(0, 9), array('-', '.')));
						}
						$encodeCount = 0;
						foreach($mapping as $left => $map) {							
							$mapping[$left] = array_combine(array_keys($map), range($encodeCount, $encodeCount+63));
							$encodeCount += 64;
						}
						$url .= 'chd=e:';
						foreach($this->Data->data as $data) {
							$data_set = null;
							foreach($data as $datum) {
								if(empty($datum))
									$data_set .= 'AA';
								else if($datum === 'empty')
									$data_set .= '__';								
								else {
									$check = false;
									foreach(array_keys($mapping) as $map) {
										if(array_search($datum, $mapping[$map])) {
											$data_set .= $map.array_search($datum, $mapping[$map]);
											$check = true;
											continue;
										}
									}
									if(!$check)
										$data_set .= 'AA';
								}
							}
							$url .= $data_set.',';
						}						
						$url = substr($url, 0, -1);
						$url .= '&';						
						break;
					default:
						break;
				}
			}
			if(!empty($this->Graph->axis)) {
				$url .= 'chxt='.$this->Graph->axis.'&';
			}
			if(!empty($this->Graph->axis_labels)) {		
				$url .= 'chxl=';
				$labelCount = 0;
				foreach($this->Graph->axis_labels as $value) {
					if(!empty($value)) {						
						if($labelCount) {
							$url .= '|';
						}
						$url .= $labelCount.':|'.implode('|', $value);						
						$labelCount++;
					} else
						$labelCount++;										
				}
				$url .= '&';
			}
			if(!empty($this->Graph->pie_labels)) {
				$url .= 'chl=';				
				foreach($this->Graph->pie_labels as $value) {
					if(!empty($value)) {
						$url .= str_replace(' ', '+', $value).'|';
					}
				}
				$url = substr($url, 0, -1);
				$url .= '&';
			}
			if(!empty($this->Graph->label_positions)) {
				$url .= 'chxp=';
				foreach($this->Graph->label_positions as $position) {
					$url .= implode(',', $position).'|';
				}
				$url = substr($url, 0, -1);
				$url .= '&';
			}
			if(!empty($this->Graph->axis_ranges)) {				
				$url .= 'chxr='.implode(',', $this->Graph->axis_ranges).'&';				
			}
			if(!empty($this->Graph->axis_styles)) {				
				$url .= 'chxs=';
				foreach($this->Graph->axis_styles as $axis_style) {
					$url .= str_replace('#', '', implode(',', $axis_style).'|');
				}
				$url = substr($url, 0, -1);
				$url .= '&';
			}
			if(!empty($this->Graph->line_styles)) {
				$url .= 'chls=';
				foreach($this->Graph->line_styles as $line_style) {
					$url .= (implode(',', $line_style)).'|';
				}
				$url = substr($url, 0, -1);
				$url .= '&';
			}
			if(!empty($this->Graph->grid_lines)) {
				$url .= 'chg='.$this->Graph->grid_lines.'&';
			}
			if(!empty($this->Graph->markers)) {				
				$url .= 'chm=';
				foreach($this->Graph->markers as $marker) {
					$url .= (implode(',', str_replace('#', '', $marker))).'|';
				}
				$url = substr($url, 0, -1);
				$url .= '&';
			}
			
			$url = substr($url, 0, -1);	
			$this->url = $url;
			
			echo '<img src="'.$url.'"/>';
		}
		
		/* For Debug Only */
		public function debug() {			
			/*
				Description: Debug output
				Usage: $graph->Graph->debug();				
			*/
			echo '<hr>';
			echo '-- URL --<br>';
			echo $this->url.'<br>';
			echo '-- Graph --<br>';
			if(!empty($this->Graph->type)) { echo '<b>Type:</b> '.$this->Graph->type.'<br>'; }
			if(!empty($this->Graph->subtype)) { echo '<b>Subtype:</b> '.$this->Graph->subtype.'<br>'; }
			if(!empty($this->Graph->title)) { echo '<b>Title:</b> '.str_replace('+', ' ', $this->Graph->title).'<br>'; }
			if(!empty($this->Graph->title_color)) { echo '<b>Title Color:</b> '.$this->Graph->title_color.'<br>'; }
			if(!empty($this->Graph->title_size)) { echo '<b>Title Size:</b> '.$this->Graph->title_size.'<br>'; }
			if(!empty($this->Graph->legend)) { echo '<b>Legend:</b> '; print_r($this->Graph->legend); echo '<br>'; }
			if(!empty($this->Graph->line_colors)) { echo '<b>Line Colors:</b> '; print_r($this->Graph->line_colors); echo '<br>'; }
			if(!empty($this->Graph->bar_size)) { echo '<b>Bar Size:</b> '.$this->Graph->bar_size.'<br>'; }
			if(!empty($this->Graph->chart_colors)) { echo '<b>Chart Colors:</b> '; print_r($this->Graph->chart_colors); echo '<br>'; }
			if(!empty($this->Graph->chart_size)) { echo '<b>Chart Size:</b> '.$this->Graph->chart_size.'<br>'; }
			if(!empty($this->Graph->axis)) { echo '<b>Axis:</b> '.$this->Graph->axis.'<br>'; }
			if(!empty($this->Graph->axis_labels)) { echo '<b>Axis Labels:</b> '; print_r($this->Graph->axis_labels); echo '<br>'; }
			if(!empty($this->Graph->pie_labels)) { echo '<b>Pie Labels:</b> '; print_r($this->Graph->pie_labels); echo '<br>'; }
			if(!empty($this->Graph->label_positions)) { echo '<b>Label Positions:</b> '; print_r($this->Graph->label_positions); echo '<br>'; }
			if(!empty($this->Graph->axis_ranges)) { echo '<b>Axis Ranges:</b> '; print_r($this->Graph->axis_ranges); echo '<br>'; }
			if(!empty($this->Graph->axis_styles)) { echo '<b>Axis Styles:</b> '; print_r($this->Graph->axis_styles); echo '<br>'; }
			if(!empty($this->Graph->line_styles)) { echo '<b>Line Styles:</b> '; print_r($this->Graph->line_styles); echo '<br>'; }
			if(!empty($this->Graph->grid_lines)) { echo '<b>Grid Lines:</b> '.$this->Graph->grid_lines.'<br>'; }
			if(!empty($this->Graph->markers)) { echo '<b>Markers:</b> '; print_r($this->Graph->markers); echo '<br>'; }
			echo '-- Data --<br>';
			if(!empty($this->Data->encoding)) { echo '<b>Encoding:</b> '.$this->Data->encoding.'<br>'; }
			if(!empty($this->Data->scale)) { echo '<b>Scale:</b> '.$this->Data->scale.'<br>'; }
			if(!empty($this->Data->data)) { echo '<b>Data:</b> '; print_r($this->Data->data); echo '<br>'; }
		}
	}
?>