import api.dialog.DialogTypes.IdValue;
import api.dialog.DialogTypes.WindowOptions;
import api.dialog.DialogTypes.FileFilter;
import api.dialog.DialogTypes.Color;
import api.dialog.IDialog;
import js.lib.Promise;
import haxe.ds.Option;

class Clialogs implements IDialog {
	static var EMPTY_RESPONSE:Option<Bool> = None; // {type: ok, payload: []};

	static var executablePath:String;

	var defaultOptions:WindowOptions;

	public function new() {
		var exceptionMessage = 'To use dialogs you must download "clialogs" and put it in the lib folder. You can get it here: https://github.com/ideckia/clialogs';
		function checkInstalation() {
			Sys.println('Checking clialogs is installed.');
			var status = Sys.command(executablePath, ['--version']);
			if (status != 0)
				throw new haxe.Exception(exceptionMessage);
		}

		var filename = switch (Sys.systemName()) {
			case 'Windows':
				'clialogs.exe';
			default:
				'clialogs';
		}

		executablePath = haxe.io.Path.join([js.Node.__dirname, 'lib', filename]);
		checkInstalation();
		setDefaultOptions({
			height: 200,
			width: 300,
			windowIcon: '',
			dialogIcon: '',
			extraData: null
		});
	}

	public function setDefaultOptions(options:WindowOptions) {
		defaultOptions = options;
	}

	public function notify(title:String, text:String, ?options:WindowOptions) {
		runClialogs(['notification', '--title "$title"', '--text "$text"'], options);
	}

	public function info(title:String, text:String, ?options:WindowOptions) {
		runClialogs(['message-dialog', '--title "$title"', '--text "$text"', '--level info'], options);
	}

	public function warning(title:String, text:String, ?options:WindowOptions) {
		runClialogs(['message-dialog', '--title "$title"', '--text "$text"', '--level warning'], options);
	}

	public function error(title:String, text:String, ?options:WindowOptions) {
		runClialogs(['message-dialog', '--title "$title"', '--text "$text"', '--level error'], options);
	}

	public function question(title:String, text:String, ?options:WindowOptions):Promise<Bool> {
		return new Promise<Bool>((resolve, reject) -> {
			runClialogs(['message-dialog', '--title "$title"', '--text "$text"', '--level question'], options).then(optResponse -> {
				switch optResponse {
					case Some(response):
						resolve(response.type == ok);
					case _: resolve(false);
				}
			}).catchError(reject);
		});
	}

	public function selectFile(title:String, isDirectory:Bool = false, ?openDirectory:String, multiple:Bool = false, ?fileFilter:FileFilter,
			?options:WindowOptions):Promise<Option<Array<String>>> {
		return new Promise<Option<Array<String>>>((resolve, reject) -> {
			var args = ['file-dialog'];
			if (isDirectory)
				args.push('--is-directory');
			if (openDirectory != null)
				args.push('--open-directory "$openDirectory"');
			if (multiple)
				args.push('--multiple');
			runClialogs(args, options).then(optResponse -> {
				switch optResponse {
					case Some(response) if (response.type == ok):
						var paths:String = response.body[0].value;
						resolve(Some(paths.split(',')));
					case _: resolve(None);
				}
			}).catchError(reject);
		});
	}

	public function saveFile(title:String, ?saveName:String, ?openDirectory:String, ?fileFilter:FileFilter, ?options:WindowOptions):Promise<Option<String>> {
		return new Promise<Option<String>>((resolve, reject) -> {
			var args = ['file-dialog', '--save'];
			if (openDirectory != null)
				args.push('--open-directory "$openDirectory"');
			runClialogs(args, options).then(optResponse -> {
				switch optResponse {
					case Some(response) if (response.type == ok):
						resolve(Some(response.body[0].value));
					case _: resolve(None);
				}
			}).catchError(reject);
		});
	}

	public function entry(title:String, text:String, ?placeholder:String, ?options:WindowOptions):Promise<Option<String>> {
		return new Promise<Option<String>>((resolve, reject) -> {
			var args = ['input', '--title "$title"', '--label "$text"'];
			if (placeholder != null && placeholder != '')
				args.push('--hint "$placeholder"');
			runClialogs(args, options).then(optResponse -> {
				switch optResponse {
					case Some(response) if (response.type == ok):
						resolve(Some(response.body[0].value));
					case _: resolve(None);
				}
			}).catchError(reject);
		});
	}

	public function password(title:String, text:String, showUsername:Bool = false, ?options:WindowOptions):Promise<Option<{username:String, password:String}>> {
		return new Promise<Option<{username:String, password:String}>>((resolve, reject) -> {
			runClialogs([
				'log-in',
				'--title "$title"',
				'--label "$text"',
				'--user-label "username"',
				'--pass-label "password"'
			], options).then(optResponse -> {
				switch optResponse {
					case Some(response) if (response.type == ok):
						var userPass = {username: '', password: ''};
						for (b in response.body) {
							if (b.id == 'username')
								userPass.username = b.value;
							if (b.id == 'password')
								userPass.password = b.value;
						}
						resolve(Some(userPass));
					case _: resolve(None);
				}
			}).catchError(reject);
		});
	}

	public function progress(title:String, text:String, autoClose:Bool = true, ?options:WindowOptions):Progress {
		var args = ['progress', '--title "$title"', '--label "$text"'];
		return new ClialogsProgress(args.concat(buildWindowOptionArgs(options)));
	}

	public function color(title:String, initialColor:String = "#FFFFFF", ?options:WindowOptions):js.lib.Promise<Option<Color>> {
		return new Promise<Option<Color>>((resolve, reject) -> {
			runClialogs(['color', '--title "$title"', '--label "Select color"'], options).then(optResponse -> {
				switch optResponse {
					case Some(response) if (response.type == ok):
						var rgb:Array<UInt> = haxe.Json.parse(response.body[0].value);
						var color:Color = new Color({red: rgb[0], green: rgb[1], blue: rgb[2]});
						resolve(Some(color));
					case _: resolve(None);
				}
			}).catchError(reject);
		});
	}

	public function calendar(title:String, text:String, ?year:UInt, ?month:UInt, ?day:UInt, ?dateFormat:String,
			?options:WindowOptions):js.lib.Promise<Option<String>> {
		return new Promise<Option<String>>((resolve, reject) -> {
			var args = ['calendar', '--title "$title"', '--label "$text"'];
			if (dateFormat != null)
				args.push('--date-format $dateFormat');
			runClialogs(args, options).then(optResponse -> {
				switch optResponse {
					case Some(response) if (response.type == ok):
						var date:String = response.body[0].value;
						resolve(Some(StringTools.replace(date, 'UTC', '')));
					case _: resolve(None);
				}
			}).catchError(reject);
		});
	}

	public function list(title:String, text:String, columnHeader:String, values:Array<String>, multiple:Bool = false,
			?options:WindowOptions):js.lib.Promise<Option<Array<String>>> {
		return new Promise<Option<Array<String>>>((resolve, reject) -> {
			var args = ['list', '--title "$title"', '--header "$columnHeader"'];

			for (v in values)
				args.push('-v "$v"');

			runClialogs(args, options).then(optResponse -> {
				switch optResponse {
					case Some(response) if (response.type == ok):
						var paths:String = response.body[0].value;
						resolve(Some(paths.split(',')));
					case _: resolve(None);
				}
			}).catchError(reject);
		});
	}

	public function custom(definitionPath:String):Promise<Option<Array<IdValue<String>>>> {
		return new Promise<Option<Array<IdValue<String>>>>((resolve, reject) -> {
			runClialogs(['custom', '--layout-path "$definitionPath"']).then(optResponse -> {
				switch optResponse {
					case Some(response) if (response.type == ok):
						resolve(Some(response.body));
					case _: resolve(None);
				}
			}).catchError(reject);
		});
	}

	function buildWindowOptionArgs(?options:WindowOptions) {
		return [].concat(writeArgument(options, 'icon-path', 'windowIcon'));
	}

	function writeArgument(options:WindowOptions, argumentName:String, fieldName:String) {
		var value = Reflect.field(options, fieldName);
		var defValue = Reflect.field(defaultOptions, fieldName);
		inline function isBlank(s:String)
			return s == null || StringTools.trim(s) == '';
		if (isBlank(value) && isBlank(defValue))
			return [];
		else if (isBlank(value))
			return ['--$argumentName $defValue'];
		else
			return ['--$argumentName $value'];
	}

	function runClialogs(args:Array<String>, ?options:WindowOptions):js.lib.Promise<Option<ClialogResponse>> {
		return new Promise<Option<ClialogResponse>>((resolve, reject) -> {
			var cp = js.node.ChildProcess.spawn(executablePath, buildWindowOptionArgs(options).concat(args), {shell: true});

			var data = '';
			var error = '';
			cp.stdout.on('data', d -> data += d);
			cp.stdout.on('end', d -> {
				var cleanData = cleanResponse(data);
				if (error != '' || cleanData.length == 0)
					resolve(None);
				else {
					resolve(Some(haxe.Json.parse(cleanData)));
				}
			});
			cp.stderr.on('data', e -> error += e);
			cp.stderr.on('end', e -> {
				if (error != '')
					reject(error);
			});

			cp.on('error', (error) -> {
				reject(error);
			});
		});
	}

	inline function cleanResponse(response:String) {
		return ~/\r?\n/g.replace(response, '');
	}
}

@:access(Clialogs)
class ClialogsProgress implements Progress {
	var process:js.node.child_process.ChildProcess;

	public function new(args:Array<String>) {
		process = js.node.ChildProcess.spawn(Clialogs.executablePath, args, {shell: true});
	}

	@:keep
	public function progress(percentage:UInt) {
		process.stdin.write('progress-$percentage\n');
	}
}

typedef ClialogResponse = {
	var type:ClialogResponseType;
	var body:Array<IdValue<String>>;
}

enum abstract ClialogResponseType(String) {
	var ok;
	var cancel;
}
