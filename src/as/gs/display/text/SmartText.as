package gs.display.text 
{
	import gs.util.BitmapUtils;
	import gs.util.FontUtils;
	
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.text.Font;
	import flash.text.TextField;
	
	/**
	 * The SmartText class contains a text field and
	 * manages using embedded fonts or bitmapping the
	 * text field after rendering system fonts.
	 */
	public class SmartText extends Sprite
	{
		
		/**
		 * The text field.
		 */
		public var field:TextField;
		
		/**
		 * Whether or not the bitmapped version is
		 * shown.
		 */
		public var isBitmapped:Boolean;
		
		/**
		 * bitmap.
		 */
		private var bmp:Bitmap;
		
		/**
		 * Constructor for SmartText instances.
		 * 
		 * @param field The text field.
		 */
		public function SmartText(_field:TextField=null)
		{
			if(!_field)return;
			this.field=_field;
			this.x=field.x;
			this.y=field.y;
			field.x=0;
			field.y=0;
			addChild(field);
		}
		
		/**
		 * @private
		 */
		public function testBitmap():void
		{
			addBitmap();
		}
		
		/**
		 * Text value.
		 */
		public function set text(val:String):void
		{
			if(!field)
			{
				trace("WARNING: SmartText instance's field property is null, not doing anything.");
				return;
			}
			var f:Font=FontUtils.getFontFromTextFormat(field.defaultTextFormat);
			if(!f || !f.hasGlyphs(val))
			{
				field.embedFonts=false;
				field.text=val;
				addBitmap();
			}
			else
			{
				field.embedFonts=true;
				field.text=val;
				removeBitmap();
			}
		}
		
		/**
		 * Text value.
		 */
		public function get text():String
		{
			return field.text;
		}
		
		/**
		 * Removes the bitmap and shows the text field.
		 */
		private function removeBitmap():void
		{
			if(bmp)removeChild(bmp);
			field.x=0;
			field.y=0;
			addChild(field);
			isBitmapped=false;
		}
		
		/**
		 * Removes the label and shows the bitmap.
		 */
		private function addBitmap():void
		{
			bmp=BitmapUtils.bitmapDisplayObject(field);
			bmp.x=0;
			bmp.y=0;
			addChild(bmp);
			removeChild(field);
			isBitmapped=true;
		}
	}
}