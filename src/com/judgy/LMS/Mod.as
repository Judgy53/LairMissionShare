import com.GameInterface.DistributedValue;
import com.GameInterface.QuestsBase;
import com.GameInterface.Quest;
import mx.utils.Delegate;

class com.judgy.LMS.Mod {
	private var m_swfRoot:MovieClip; 
	
	private var Dval_ShareOnce:DistributedValue;
	private var Dval_ShareLoop:DistributedValue;
	
	private var loopInterval:Number;
	
	public static function main(swfRoot:MovieClip) {
		var s_app = new Mod(swfRoot);
		
		swfRoot.onLoad = function() { s_app.Load(); };
		swfRoot.onUnload = function() { s_app.Unload(); };
	}
	
	public function Mod(swfRoot:MovieClip) {
		m_swfRoot = swfRoot;
		
		Dval_ShareOnce = DistributedValue.Create("LMS_ShareOnce");
		Dval_ShareOnce.SetValue(false);
		
		Dval_ShareLoop = DistributedValue.Create("LMS_ShareLoop");
		Dval_ShareLoop.SetValue(false);
		
		loopInterval = -1;
    }
	
	public function Load():Void {
		Dval_ShareOnce.SignalChanged.Connect(SlotShareOnce, this);
		Dval_ShareLoop.SignalChanged.Connect(SlotShareLoop, this);
	}
	
	public function OnUnload():Void {
		Dval_ShareOnce.SignalChanged.Disconnect(SlotShareOnce, this);
		Dval_ShareLoop.SignalChanged.Disconnect(SlotShareLoop, this);
		
		EndLoop();
	}
	
	//Share all lair missions to the group/raid
	public function ShareMissions():Void {
		var activeQuests:Array = QuestsBase.GetAllActiveQuests();
		if (activeQuests == null || activeQuests.length == 0) {
			Log("No Mission to share.");
			return;
		}
		var sharedQuests:Array = new Array();
		for (var i:Number = 0; i < activeQuests.length; i++) {
			var quest:Quest = activeQuests[i];
			if (quest.m_MissionType == _global.Enums.MainQuestType.e_Item && quest.m_MissionIsNightmare) { //is sidequest and lair quest
				QuestsBase.ShareQuest(quest.m_ID);
				sharedQuests.push(quest.m_MissionName);
			}
		}
		if (sharedQuests.length == 0) {
			Log("No Mission to share.");
			return;
		}
		Log("Shared " + sharedQuests.length + " missions : " + sharedQuests.join(", "));
	}
	
	//Start a loop to share missions every 5 seconds
	public function StartLoop():Void {
		if (loopInterval != -1)
			return;
		
		loopInterval = setInterval(Delegate.create(this, ShareMissions), 5000);
		Log("Mission share loop started.");
		ShareMissions(); //Trigger manually the first call
	}
	
	//End the share loop
	public function EndLoop():Void {
		if (loopInterval == -1)
			return;
		
		clearInterval(loopInterval);
		loopInterval = -1;
		
		Log("Mission share loop stopped.");
	}
	
	//Triggered on command "/setoption LMS_ShareOnce true"
	private function SlotShareOnce(dv:DistributedValue):Void {
		var val = dv.GetValue();
		if (val) {
			ShareMissions();
			dv.SetValue(false);
		}
	}
	
	//Triggered on command "/setoption LMS_ShareLoop <true/false>"
	private function SlotShareLoop(dv:DistributedValue):Void {
		var val = dv.GetValue();
		if (val)
			StartLoop();
		else
			EndLoop();
	}
	
	//Log string in System channel with LMS prefix
	private function Log(str:String):Void {
		com.GameInterface.UtilsBase.PrintChatText("[LMS] " + str);
	}
}