<?php

 /* This script was written by Thorsten Rotering, 2009-2011.
  *
  * This script is free software: you can redistribute it and/or modify
  * it under the terms of the Lesser GNU General Public License (LGPL) as
  * published by the Free Software Foundation, either version 3 of the
  * License or (at your option) any later version.
  *
  * This script is distributed in the hope that it will be useful, but
  * WITHOUT ANY WARRANTY; without even the implied warranty of
  * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  * General Public License for more details.
  *
  * You should received a copy of the GNU General Public License and the
  * Lesser GNU General Public License with this script. If not, see
  * <http://www.gnu.org/licenses/>. */


 /* Check, if the script can be interpreted by the local PHP version */
 if (version_compare('5.0.0', PHP_VERSION, '>'))
  trigger_error('The class \'PageNavigation\' cannot be interpreted by the local PHP version, as it requires PHP 5.0 or above', E_USER_ERROR);


 class PageNavigation {
  const version = '1.0.5';
  const pubname = 'PageNavigation';

  /* Read-only attributes */
  private $parameter_name;
  private $cur_page_id;
  private $first_item_id;
  private $last_item_id;
  private $item_count;
  private $items_per_page;
  private $page_count;
  private $sql_limit;

  /* Settings */
  public $url = '?%p';
  public $show_navlinks = true;
  public $use_xhtml = true;
  public $link_count_outer = 1;
  public $link_count_inner = 3;

  /* HTML classes */
  public $html_class_pagebar = 'pagebar';
  public $html_class_pagebar_label = 'pagebar-label';
  public $html_class_pagebar_curpage = 'pagebar-curpage';
  public $html_class_pagebar_pagelink = 'pagebar-link pagebar-pagelink';
  public $html_class_pagebar_navlink_prev = 'pagebar-link pagebar-navlink pagebar-navlink-prev';
  public $html_class_pagebar_navlink_next = 'pagebar-link pagebar-navlink pagebar-navlink-next';
  public $html_class_pageselbox = 'pageselbox';
  public $html_class_pageselbox_select = 'pageselbox-select';
  public $html_class_pageselbox_button = 'pageselbox-button';

  /* HTML labels */
  public $html_label_pagebar = 'sites:';
  public $html_label_pageselbox_button = 'Go!';
  public $html_label_pagelink = 'goto page %p';
  public $html_label_pagelink_divider = '&hellip;';
  public $html_label_navlink_prev = 'Vorherige Seite';
  public $html_label_navlink_prev_symbol = '&laquo;';
  public $html_label_navlink_next = 'N&auml;chste Seite';
  public $html_label_navlink_next_symbol = '&raquo;';



  /* The constructor */
  public function __construct ($item_count, $items_per_page, $parameter_name = 'p') {

   /* Set the items per subpage */
   $this->items_per_page = max((int)$items_per_page, 1);

   /* Set the number of items overall */
   $this->item_count = max((int)$item_count, 0);

   /* Set the paramter name */
   $this->parameter_name = $parameter_name;

   /* Calculate the number of subpages */
   $this->page_count = max(ceil($this->item_count / $this->items_per_page), 1);

   /* Detect the requested subpage */
   if (isset($_POST[$this->parameter_name]))
    $cur_page_id = (int)$_POST[$this->parameter_name];
   elseif (isset($_GET[$this->parameter_name]))
    $cur_page_id = (int)$_GET[$this->parameter_name];
   else
    $cur_page_id = 1;
   
   $this->cur_page_id = max(min($cur_page_id, $this->page_count), 1);

   /* Calculate the first and last item ID and the SQL limits */
   $offset = ($this->cur_page_id - 1) * $this->items_per_page;
   $this->first_item_id = $offset + 1;
   $this->last_item_id = min($offset + $this->items_per_page, $this->item_count);
   $this->sql_limit = (string)$offset . ', ' . (string)$this->items_per_page;
  }


  /* Enable read-access to all attributes */
  public function __get ($var_name) {
   return $this->$var_name;
  }


  /**
   * Creates an HTML page bar to navigate the subpages.
   * @param string $html_id (optional) If specified, the surrounding division will get a specific html id.
   * @return string
   */
  public function createPageBar ($html_id = 'pagebar') {

   /* Initial calculations */
   $minblocksize = $this->link_count_outer + $this->link_count_inner;

   /* Open the division */
   $output = '<div id="' . $html_id . '" class="' . $this->html_class_pagebar . '">';
   if (!empty($this->html_label_pagebar)) $output .= '<span class="' . $this->html_class_pagebar_label . '">' . $this->html_label_pagebar . '</span> ';

   /* Create the link to the previous page */
   if ($this->show_navlinks && !empty($this->html_label_navlink_prev_symbol) && $this->cur_page_id > 1)
    $output .= '<a class="' . $this->html_class_pagebar_navlink_prev . '" href="' . $this->getUrl($this->cur_page_id - 1) .
               '" title="' . $this->html_label_navlink_prev . '" rel="prev">' . $this->html_label_navlink_prev_symbol . '</a> ';

   /* Create the left link block of the subpages */
   if ($this->cur_page_id > $minblocksize + 1)
    $output .= $this->getPageLinks(1, $this->link_count_outer) .
               $this->html_label_pagelink_divider . ' ' .
               $this->getPageLinks($this->cur_page_id - $this->link_count_inner, $this->cur_page_id - 1);
   else
    $output .= $this->getPageLinks(1, $this->cur_page_id - 1);

   /* Create the information about the current page */
   $output .= '<strong class="' . $this->html_class_pagebar_curpage . '">' . $this->cur_page_id . '</strong> ';

   /* Create the right link block of the subpages */
   if ($this->cur_page_id < $this->page_count - $minblocksize)
    $output .= $this->getPageLinks($this->cur_page_id + 1, $this->cur_page_id + $this->link_count_inner) .
               $this->html_label_pagelink_divider . ' ' .
               $this->getPageLinks($this->page_count - $this->link_count_outer + 1, $this->page_count);
   else
    $output .= $this->getPageLinks($this->cur_page_id + 1, $this->page_count);

   /* Create the link to the next page */
   if ($this->show_navlinks && !empty($this->html_label_navlink_next_symbol) && $this->cur_page_id < $this->page_count)
    $output .= '<a class="' . $this->html_class_pagebar_navlink_next . '" href="' . $this->getUrl($this->cur_page_id + 1) .
               '" title="' . $this->html_label_navlink_next . '" rel="next">' . $this->html_label_navlink_next_symbol . '</a>';

   /* Close the division */
   $output .= '</div>';
   return $output;
  }


  /**
   * Creates an HTML selection box to navigate the subpages.
   * @param string $html_id (optional) If specified, the surrounding division will get a specific html id.
   * @return string
   */
  public function createPageSelBox ($html_id = 'pageselbox') {

   /* Precreate the selection box */
   $selbox = '<select name="' . $this->parameter_name . '" class="' . $this->html_class_pageselbox_select . '" size="1">';

   for ($n = 1; $n <= $this->page_count; $n++)
   	$selbox .= '<option value="' . (string)$n . '"' . ($n == $this->cur_page_id ? ' selected="selected"' : '') . '>' . (string)$n . '</option>';

   $selbox .= '</select>';

   /* Create the division */
   $output = '<div id="' . $html_id . '" class="' . $this->html_class_pageselbox . '">' .
             '<form action="' . $this->getUrl(0) . '" method="post"><div>' .
             str_replace('%p', $selbox, $this->html_label_pagelink) . ' ' .
             '<input type="submit" class="' . $this->html_class_pageselbox_button . '" value="' . $this->html_label_pageselbox_button . '"' .
             ($this->use_xhtml ? ' />' : '>') .
             '</div></form></div>';

   /* Finalize */
   return $output;
  }

  
  /**
   * Returns the url to a subpage.
   * @param int $page_id (optional) If specified, the placeholder %p will be replaced with the specified id of the subpage.
   * @return string
   */
  public function getUrl ($page_id = -1) {
   if ($page_id == -1)
    return $this->url;      
   elseif ($page_id == 0) {
    $url = $this->url;
   	$url = str_replace('&%p', '', $url);
   	$url = str_replace('?%p', '', $url);
   } else
    $url = str_replace('%p', $this->parameter_name . '=' . (string)$page_id, $this->url);

   $url = htmlspecialchars($url);
   return $url;
  }
  

  /**
   * Returns a continuous list of links to subpages in a specified range.
   * @param int $first The id of the first element to include.
   * @param int $last The id of the last element to include.
   * @return string
   */
  private function getPageLinks ($first, $last) {
   $output = '';
   for ($n = $first; $n <= $last; $n++)
    $output .= '<a class="' . $this->html_class_pagebar_pagelink . '" href="' . $this->getUrl($n) . '" title="' . str_replace('%p', (string)$n, $this->html_label_pagelink) . '">' . (string)$n . '</a> ';
   return $output;
  }

 }

?>