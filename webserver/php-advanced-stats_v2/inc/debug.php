<?php
/**
*	Debug class for PHP
*
*	@package    Debug
*	@subpackage Commons
*	@version	1.0
*	@license    http://opensource.org/licenses/GPL-3.0  GNU General Public License, version 3 (GPL-3.0)
*	@author     Olaf Erlandsen <olaftriskel@gmail.com>
*/
class Debug
{
	private static $level = 0;
	private static $lines = 5;
	private static $debug = true;
	private static $data;
	private static $output = 'html';
	private static $alerts = array();
	/**
	*	__construct function
	*	magic method
	*
	*	@return null
	*/
	public function __construct()
	{
	}
	/**
	*	__callstatic function
	*	magic method
	*
	*	@param	string	$method
	*	@param	array	$args
	*	@return null
	*/
	public static function __callstatic( $method , $args )
	{
		if( strtolower($method) == '_print' )
		{
			return call_user_func_array( array( self , 'printData' ) , $args );
		}else{
			self::$level = 1;
	 		self::alert("Method does not exists");;
		}
	}
	/**
	*	Debug reporting
	*
	*	@param	bool	$debug
	*	@return null
	*/
	public static function debug( $debug = true )
	{
		if( is_bool( $debug ) )
		{
			self::$debug = $debug;
		}
		return new self;
	}
	/**
	*	Set output format
	*	JSON|HTML|TEXT
	*
	*	@param	string	$output	( html, text and json )
	*	@return object	self
	*/
	public static function output( $output )
	{
		if( in_array( mb_strtolower( $output ) , array('json','html','text') ) )
		{
			self::$output = mb_strtolower($output);
		}
		return new self;
	}
	/**
	*	Error function
	*	Create Error
	*
	*	@param	int		$errno		Error numebr
	*	@param	string	$errst		Message 
	*	@param	string	$errfile	Error file
	*	@param	string	$errline	Error line
	*	@param	array	$errcontext	Context
	*	@return string
	*/
	public static function  error($errno , $errstr = null , $errfile = null ,  $errline = null , array $errcontext = array() )
	{
		self::$alerts[ sha1($errline . $errfile) ] = array(
			'data'		=>	array(
				'line'	=>	$errline,
				'file'	=>	$errfile,
				'error'	=>	$errno,
				'type'	=>	'error',
			),
			'message'	=>	self::replace( $errstr ),
			'code'		=>	self::_lines( $errfile , $errline ),
		);
		self::destructor();
		return true;
	}
	/**
	*	Exception object parser
	*
	*	@param	int	$excepcion Exception object
	*	@return null
	*/
	public static function  exception( $excepcion )
	{
		self::$alerts[ sha1($excepcion->getLine() . $excepcion->getFile()) ] = array(
			'data'		=>	array(
				'line'	=>	$excepcion->getLine(),
				'file'	=>	$excepcion->getFile(),
				'error'	=>	$excepcion->getCode(),
				'type'	=>	'exception',
			),
			'message'	=>	self::replace( $excepcion->getMessage() ),
			'code'		=>	self::_lines( $excepcion->getFile() , $excepcion->getLine() ),
		);
		self::destructor();
		return true;
	}
	/**
	*	Shutdown function
	*
	*	@return null
	*/
	public static function  shutdown( )
	{
		$error = error_get_last();
		if( count( $error ) > 0 )
		{
			if( !array_key_exists(  sha1($error['line'] . $error['file'] ) , self::$alerts ) )
			{
				self::$alerts[ sha1($error['line'] . $error['file'])  ] = array(
					'data'		=>	array(
						'line'	=>	$error['line'],
						'file'	=>	$error['file'],
						'error'	=>	null,
						'type'	=>	'error',
					),
					'message'	=>	self::replace( $error['message'] ),
					'code'		=>	self::_lines( $error['file'] , $error['line'] ),
				);
			}
		}
		self::destructor();
		return true;
	}
	/**
	*	Create Dubugger/Print
	*
	*	@param	mixed	$code
	*	@param	string	$message
	*	@param	array	$replace
	*	@return null
	*/
	public static function printData( $code  , $message = "User print" , array $replace = array() )
	{
		$backtrace = debug_backtrace( DEBUG_BACKTRACE_IGNORE_ARGS , 0 );
		$data = $backtrace[ 0 ];
		self::$alerts[ sha1($data['line'] . $data['file'] ) ] = array(
			'data'		=>	array(
				'line'	=>	$data['line'] ,
				'file'	=>	$data['file'] ,
				'error'	=>	false,
				'type'	=>	'print',
			),
			'message'	=>	self::replace( $message , $replace ),
			'code'		=>	self::_lines( $code ),
		);
		self::destructor();
	}
	/**
	*	Create Alert
	*
	*	@param	string	$string
	*	@param	replace	$replace
	*	@param	array	$backtrace
	*	@return null
	*/
	public static function alert( $string , array $replace = array() , array $backtrace = array() )
	{
		if( count($backtrace) == 0 )
		{
			$backtrace = debug_backtrace( DEBUG_BACKTRACE_IGNORE_ARGS );
			if( array_key_exists( self::$level , $backtrace ) )
			{
				$data = $backtrace[ self::$level ];
				if( array_key_exists( self::$level+1 , $backtrace ) and in_array(strtolower($data['function']),array('__call','__callstatic')))
				{
					$data = $backtrace[ self::$level+1];
				}
			}
		}else{
			$data = $backtrace;
		}
		self::$alerts[] = array(
			'data'		=>	$data,
			'message'	=>	self::replace( $string , $replace ),
			'code'		=>	self::_lines( $data['file'] , $data['line'] ),
		);
		self::destructor();
	}
	/**
	*	Backtrace level
	*
	*	@param	int	$level
	*	@return object self
	*/
	public static function level( $level )
	{
		self::$level = abs(int($level));
		return new self;
	}
	/**
	*	Set lines
	*
	*	@param	int	$absoluteNumber
	*	@return object self
	*/
	public static function lines( $absoluteNumber )
	{
		self::$lines = abs(intval($absoluteNumber));
		return new self;
	}
	/**
	*	Set lines to show
	*
	*	@param	int	$absoluteNumber
	*	@return object self
	*/
	private static function _lines( $file , $point = null )
	{
		$space = ( self::$output == 'json' ) ? "\t" : " " ;
		if( is_null( $point ) )
		{
			$file = print_r($file,true);
			$file = preg_split('/\n/', $file );
			$file = str_replace(' ', $space, $file );
		}else{
			$file = file( $file );
			$file = array_slice( $file , max($point-self::$lines-1,0) , (self::$lines*2+1) , true );
		}
		return $file;
	}
	/**
	*	Print all alerts
	*
	*	@return null
	*/
	private static function destructor()
	{
		if( self::$debug === false )
		{
			return false;
		}
		if( count( self::$alerts ) > 0 )
		{
			if( self::$output == 'json' )
			{
				@header('content-type:application/json');
				echo json_encode( self::$alerts );
			}
			else if( self::$output == 'text' )
			{
				header("Content-Type: text/plain");
				$text = "";
				foreach( self::$alerts AS $alert)
				{
					$text .= str_repeat("=", 10)."\n";
					$text .= preg_replace("/\s+/",' ',$alert['message'])."\n";
					$text .= str_repeat("=", 10)."\n";
					foreach( $alert['code'] AS $index => $line )
					{
						$text .= ($index+1) . "- \t" . htmlentities( $line , ENT_COMPAT , 'UTF-8' , true )."\n";
					}
					$text .="\n";
					$text .= "[In file ".$alert['data']['file']." on line ".$alert['data']['line']."]";
					$text .="\n\n";
				}
				echo $text;
			}else{
				$html = '';
				$html .= '<style>';
					$html .= '.debug{z-index:2147483647;font-size:100%;font-family:arial,sans-serif,tahoma;position:absolute;top:0;left:0;width:100%;min-height:auto;height:100%;text-align:center;margin:0;padding:0;background:#eeeeee;}';
					$html .= '.debug .item{background:white;text-align:left;width:80%;margin:1.0% auto;border:1px solid red;display:block;padding:0 19px 0px;border: 1px solid #dddddd;-webkit-border-radius: 4px;-moz-border-radius: 4px;border-radius: 4px;}';
					$html .= '.debug .item .message{}';
					$html .= '.debug .item .code{border:1px solid red;display:block;padding:0 19px 0;border: 1px solid #ddd;-webkit-border-radius: 4px;-moz-border-radius: 4px;border-radius: 4px;-webkit-box-shadow: inset 40px 0 0 #fbfbfc, inset 41px 0 0 #ececf0;-moz-box-shadow: inset 40px 0 0 #fbfbfc, inset 41px 0 0 #ececf0;box-shadow: inset 40px 0 0 #fbfbfc, inset 41px 0 0 #ececf0;}';
					$html .= '.debug .item .code ol{display: block;list-style-type: decimal;-webkit-margin-before: 1em;-webkit-margin-after: 1em;-webkit-margin-start: 0px;-webkit-margin-end: 0px;-webkit-padding-start: 34px;}';
					$html .= '.debug .item .code ol li{padding-left: 12px;color: #bebec5;line-height: 20px;text-shadow: 0 1px 0 #fff;}';
					$html .= '.debug .item .code ol li.flag code{background-color:#FF8080;color:white;text-shadow: 0 1px 0 #cccccc;}';
					$html .= '.debug .item .code ol li code{}';
					$html .= '.debug .item .info{}';
					$html .= '.debug .item .info{}';
				$html .= '</style>';
				$html .= '<div class="debug">';
				foreach ( self::$alerts AS $alert )
				{
					$html .= '<div class="item">';
						$html .= '<p class="message">';
							$html .= htmlentities( $alert[ 'message' ] , ENT_COMPAT , 'UTF-8' , true );
						$html .= '</p>';
						$html .= '<pre class="code">';
							$html .= '<ol>';
								foreach( $alert['code'] AS $index => $line )
								{
									if ( $alert['data']['line'] === ($index+1) )
									{
										$html .= '<li class="flag" value="'.($index+1).'">';
									}else{
										$html .= '<li value="'.($index+1).'">';
									}
										$html .= '<code>';
											$html .= preg_replace('/\t/','&nbsp;&nbsp;&nbsp;&nbsp;',htmlentities( $line , ENT_COMPAT , 'UTF-8' , true ));
										$html .= '</code>';
									$html .= '</li>';
								}
							$html .= '</ol>';
						$html .= '</pre>';
						$html .= '<p class="info">';
							$html .= 'In file '.$alert['data']['file'] .' on line '. $alert['data']['line'];
						$html .= '</p>';
					$html .= '</div>';
				}
				$html .= '</div>';
				echo $html;
			}
		}
	}
	/**
	*	Replace string
	*
	*	@param	string	$haystack
	*	@param	array	$replacement 
	*	@return string
	*/
	private static function replace( $string , array $replace = array() )
	{
		foreach( $replace AS $key => $value )
		{
			$string = str_replace( ':'.  $key .':' , $value , $string );
		}
		return $string;
	}
	/**
	*	Count alerts
	*
	*	@return int
	*/
	public static function count()
	{
	 	return count(self::$alerts);
	}
	/**
	*	Register shutdown function, error and exception handlers.
	*
	*	@return object	self
	*/
	public static function register()
	{
		error_reporting(0);
		ini_set('error_reporting',0);
		ini_set('display_errors',1);
		set_error_handler(array('Debug','error'),E_ALL);
		set_exception_handler(array('Debug','exception'));
		register_shutdown_function(array('Debug','shutdown'));
		return new self;
	}
}
?>
