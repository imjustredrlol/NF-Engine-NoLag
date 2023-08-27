package substates;

import flash.geom.Rectangle;
import tjson.TJSON as Json;
import haxe.format.JsonParser;
import haxe.io.Bytes;

import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxSort;
import flixel.util.FlxSpriteUtil;
import lime.media.AudioBuffer;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.Assets as OpenFlAssets;

import flixel.addons.transition.FlxTransitionableState;

import backend.Song;
import backend.Section;
import backend.StageData;


import objects.AttachedSprite;
import substates.Prompt;

#if sys
import flash.media.Sound;
import sys.io.File;
import sys.FileSystem;
#end

#if android
import android.flixel.FlxButton;
#else
import flixel.ui.FlxButton;
#end

@:access(flixel.sound.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)



class OSTSubstate extends MusicBeatSubstate
{
    public static var vocals:FlxSound = null;
    var left:FlxSprite;
    var flashSpr:FlxSprite;
    var _rect:Rectangle;
    var _temprect:Rectangle;
    
    var snd = FlxG.sound.music;

		var currentTime:Float = 0;
		
		var buffer:AudioBuffer;
		var bytes:Bytes = FlxG.sound.music._sound.__buffer.data.toBytes();
		
		var byteLength:Float = 0;
		var khz:Float = 0;
		var channels:Float = 0;
		var stereo:Float = 0;
		
		var index:Float = 0;
		var samples:Float = 0;//Math.floor((currentTime + (((60 / Conductor.bpm) * 1000 / 4) * 16)) * khz - index);
		var samplesPerRow:Float = 0;

		var lmin:Float = 0;
		var lmax:Float = 0;

		var rmin:Float = 0;
		var rmax:Float = 0;

		var rows:Float = 0;
		var render:Int = 0;
		var prevRows:Float = 0;
        var midx:Float = 0;
    
	public function new(needVoices:Bool,bpm:Float)
	{
		super();				
		
		if (needVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();
		
		FlxG.sound.list.add(vocals);
		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
		vocals.play();
		vocals.persist = true;
		vocals.looped = true;
		vocals.volume = 0.7;		
		
		left = new FlxSprite().makeGraphic(1280, 720, 0xFF000000, false, "lchannelw");
		left.alpha = 0.5;
		add(left);
		
		flashSpr = new FlxSprite();
		flashGFX = flashSpr.graphics;
		
		currentTime = snd.time;
		
		buffer = snd._sound.__buffer;
		bytes = buffer.data.buffer;
		
		byteLength = bytes.byteLength - 1;
		khz = (buffer.sampleRate / 1000);
		channels = buffer.channels;
		stereo = channels > 1;
		
		index = Math.floor(currentTime * khz);
		samples = 720;//Math.floor((currentTime + (((60 / Conductor.bpm) * 1000 / 4) * 16)) * khz - index);
		samplesPerRow = samples / 720;

		lmin = 0;
		lmax = 0;

		rmin = 0;
		rmax = 0;

		rows = 0;
		render = 0;
		prevRows = 0;
		
		//game.add(right);
		
		//flashGFX = FlxSpriteUtil.flashGfx;
		
		_rect = new Rectangle(0, 0, 1280, 720);
		_temprect = new Rectangle(0, 0, 0, 0);
		midx = 720 / 2;
		
	}

	
	override function update(elapsed:Float)
	{
		if(FlxG.keys.justPressed.ESCAPE #if android || FlxG.android.justReleased.BACK #end)
		{
		    FlxG.sound.music.volume = 0;
		    destroyVocals();
		
		    FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);		
		    
			#if android
			FlxTransitionableState.skipNextTransOut = true;
			FlxG.resetState();
			#else
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			#end
		}
		
		left.pixels.lock();
		left.pixels.fillRect(_rect, 0xFF000000);
		
		//right.pixels.lock();
		//right.pixels.fillRect(_rect, 0xFF000000);

		FlxSpriteUtil.beginDraw(0xFFFFFFFF);
		flashGFX.clear(); flashGFX.beginFill(0xFFFFFF, 1);
		
		
		
		while (index < byteLength) {
			if (index >= 0) {
				var byte = bytes.getUInt16(index * channels * 2);

				if (byte > 65535 / 2) byte -= 65535;

				var sample = (byte / 65535);

				if (sample > 0) {
					if (sample > lmax) lmax = sample;
				} else if (sample < 0) {
					if (sample < lmin) lmin = sample;
				}

				if (stereo) {
					var byte:Float = bytes.getUInt16((index * channels * 2) + 2);

					if (byte > 65535 / 2) byte -= 65535;

					var sample:Float = (byte / 65535);

					if (sample > 0) {
						if (sample > rmax) rmax = sample;
					} else if (sample < 0) {
						if (sample < rmin) rmin = sample;
					}
				}
			}
			
			if (rows - prevRows >= samplesPerRow) {
				prevRows = rows + ((rows - prevRows) - 1);
				
				flashGFX.drawRect(render, midx + (rmin * midx * 2), 1, (rmax - rmin) * midx * 2);
				//flashGFX2.drawRect(midx + (rmin * midx * 2), render, (rmax - rmin) * midx * 2, 1);
				
				
				
				lmin = lmax = rmin = rmax = 0;
				render++;
			}
			
			index++;
			rows++;
			if (render > 720-1) break;
		}
		
		flashGFX.endFill();
		left.pixels.draw(flashSpr);
		left.pixels.unlock();
		
		return;
		
		super.update(elapsed);
	}

	public static function destroyVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}
}