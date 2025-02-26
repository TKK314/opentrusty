var ValidatorOnLoad_original = null;

// 初期化のための関数を置き換えて、後にInitAndApplyBackgroundが呼び出されたときに初期化されるようにします。
function DelayLoadingEvent() {
    if (typeof (ValidatorOnLoad) == 'function') {
        ValidatorOnLoad_original = ValidatorOnLoad;
        ValidatorOnLoad = null;
    }
}

// バリデーターを初期化して、検証コントロールが背景色を変えられるようにします。
function InitAndApplyBackground() {
    // 初期化されていなければ、初期化関数を呼び出します。
    if (typeof (Page_ValidationActive) == 'undefined' || !Page_ValidationActive) {
        if (typeof (ValidatorOnLoad_original) == 'function') {
            ValidatorOnLoad_original();
        } else if (typeof (ValidatorOnLoad) == 'function') {
            ValidatorOnLoad();
        }
    }

    if (typeof (Page_Validators) == 'undefined' || !Page_Validators) {
        return;
    }

    for (var i = 0; i < Page_Validators.length; i++) {
        var val = Page_Validators[i];
        if (val.backgroundcolor) {
            ApplyBackground(val);
        }
    }
}

// バリデーターを初期化して、検証コントロールが背景色を変えられるようにします。
function InitAndApplyBackgroundById(id) {
    // 初期化されていなければ、初期化関数を呼び出します。
    if (typeof (Page_ValidationActive) == 'undefined' || !Page_ValidationActive) {
        if (typeof (ValidatorOnLoad_original) == 'function') {
            ValidatorOnLoad_original();
        } else if (typeof (ValidatorOnLoad) == 'function') {
            ValidatorOnLoad();
        }
    }

    if (typeof (Page_Validators) == 'undefined' || !Page_Validators) {
        return;
    }

    var val = document.all ? document.all[id] : document.getElementById(id);

    if (!val) {
        return;
    }

    if (typeof (val.backgroundcolor) != 'undefined') {
        ApplyBackground(val);
    }
}

// 検証コントロールが背景色を変えられるようにします。
function ApplyBackground(val) {
    try {
        // 背景色を変える検証コントロールの数を数える
        var ctrl = document.getElementById(val.controltovalidate);
        if (typeof (ctrl.ValidatorsBgLength) == 'undefined') {
            ctrl.ValidatorsBgLength = 0;
        }
        // 検証コントロールの検証用関数をラップする
        if (typeof (val.evaluationfunction) == 'function') {
            ctrl.ValidatorsBgLength += 1;
            var original = val.evaluationfunction;
            val.evaluationfunction = function () {
                var isValid = original.apply(this, arguments);
                Background_Change(val, isValid);
                return isValid;
            };
        }
    } catch (ex) {
        // ラップに失敗した場合の例外は握りつぶす
    }
}

// 検証コントロールの結果に合わせて、対象コントロールの背景色を変えます。
function Background_Change(val, isValid) {
    // 検証結果に沿った背景色を記憶しておく
    var ctrl = document.getElementById(val.controltovalidate);
    if (typeof (ctrl.ValidatorsBgColor) == 'undefined') {
        ctrl.ValidatorsBgColor = new Array;
    }
    var results = ctrl.ValidatorsBgColor;
    results[results.length] = isValid ? 'true' : val.backgroundcolor;
    // 検証失敗による背景色変更前の背景色を記憶しておく
    if (typeof (ctrl.designedBgColor) == 'undefined') {
        ctrl.designedBgColor = ctrl.style.backgroundColor;
    }
    // 背景色を変える検証コントロールがすべて検証を終えたなら
    // 最初に検証失敗したコントロールに設定された背景色を適用する
    if (results.length == ctrl.ValidatorsBgLength) {
        var bgColor = '';
        for (var i = 0; i < results.length; i++) {
            if (results[i] != 'true') {
                bgColor = results[i];
                break;
            }
            // すべての検証に成功した場合、背景色を元に戻す。
            if (i == results.length - 1) {
                bgColor = ctrl.designedBgColor;
            }
        }
        ctrl.style.backgroundColor = bgColor;
        ctrl.ValidatorsBgColor = undefined;
    }

    // 以下は IE9 で style の背景色を変更した場合に、検証コントロールとして
    // 定義されているラベルの文字列が表示されないバグに対する回避コード。
    // ラベルの innerHTML に変更を加えて再描画させることで、表示させる。
    // 現在見ているバリデーターが背景色を変えるものとは限らないので、常に再描画させる。
    // 条件つきコンパイルで IE 9.0 のみ setTimeout で遅延実行する。
    /*@cc_on
        @if( @_jscript_version == 9 )
        setTimeout(function () { val.innerHTML += ""; }, 0);
        @end
    @*/
    // 回避コードここまで。
}

// 検証エラー集約表示コントロールの検証関数です。
function AggregatorEvaluateIsValid(val) {
    var validators = val.validators.split(',');
    var isValid = true;
    for (var i = 0; i < validators.length; i++) {
        var v = document.getElementById(validators[i]);
        if (v == null) continue;
        if (v.isvalid == undefined) continue;
        isValid = isValid & v.isvalid;
    }
    // 以下は IE9 で style の背景色を変更した場合に、検証コントロールとして
    // 定義されているラベルの文字列が表示されないバグに対する回避コード。
    // ラベルの innerHTML に変更を加えて再描画させることで、表示させる。
    // style の変更が、エラー発見時およびエラー解除時の両タイミングがあるので常に再描画させる。
    // 条件つきコンパイルで IE 9.0 のみ setTimeout で遅延実行する。
    /*@cc_on
    @if( @_jscript_version == 9 )
        setTimeout(function () { val.innerHTML += ""; }, 0);
    @end
    @*/
    // 回避コードここまで。

    return isValid;
}

// 文字列が全角文字のみかどうかを検証
function ZenkakuMojiEvaluateIsValid(val) {
    var value = ValidatorGetValue(val.controltovalidate);
    if (ValidatorTrim(value).length == 0)
        return true;
    if (IsContainsSurrogatePair(value) || IsContainsControlCharacter(value))
        return false;
    var rx = new RegExp('^[^ -~｡-ﾟ]+$');
    var matches = rx.exec(value);
    return (matches != null && value == matches[0]);
}

// サロゲートペアチェック
function IsContainsSurrogatePair(value) {
    len = value.length;
    for (i = 0; i < len; i++) {
        // 指定インデックスのUnicode取得
        str1 = value.charCodeAt(i);
        if (i < len) {
            str2 = value.charCodeAt(i + 1);
        }
        else {
            str2 = 0;
        }

        // サロゲートペア判定
        if ((0xD800 <= str1 && str1 <= 0xDBFF) &&
			 (0xDC00 <= str2 && str2 <= 0xDFFF)) {
            return true
        }
    }
    return false
}

// サロゲートペアが含まれていないか検証する。
// 単項目チェック一覧からの禁則文字処理用 CustomAutoValidator で使用する想定。
function SurrogatePairIsValid(sender, e) {
    if (e.Value == null) {
        // null は検証を通過する
        e.IsValid = true;
        return;
    }

    e.IsValid = !IsContainsSurrogatePair(e.Value);
}


// 制御文字チェック(改行コード(CR、LF)除く)
function IsContainsControlCharacter(value) {
    len = value.length;
    for (i = 0; i < len; i++) {
        // 指定インデックスのUnicode取得
        str1 = value.charCodeAt(i);
        if (str1 != 0x000a && str1 != 0x000d && 0x0000 <= str1 && str1 <= 0x001f) {
            return true;
        }
    }
    return false
}

// 日付範囲を検証
function DateRangeEvaluateIsValid(val) {
    var value = ValidatorGetValue(val.controltovalidate);
    if (ValidatorTrim(value).length == 0)
        return true;

    var rx = new RegExp(val.datatypeexpression);
    if (!rx.test(value))
        return false;

    value = FormatToYYYYMMDD(value);

    var day, month, year;

    year = value.substr(0, 4);
    month = value.substr(4, 2);
    day = value.substr(6, 2);

    // Javascriptは、0-11で表現
    month -= 1;

    var date = new Date(year, month, day);

    if (!(typeof (date) == "object" && year == date.getFullYear() && month == date.getMonth() && day == date.getDate()))
        return false;

    var maxval = val.maximumvalue;
    var minval = val.minimumvalue;

    var maxdate, mindate;

    if (ValidatorTrim(maxval).length != 0) {
        maxdate = CreateNewDate(FormatToYYYYMMDD(maxval));
        if (maxdate < date)
            return false;
    }

    if (ValidatorTrim(minval).length != 0) {
        mindate = CreateNewDate(FormatToYYYYMMDD(minval));
        if (mindate > date)
            return false;
    }

    return true;
}

// 文字列が最小長、最大長の範囲に 収まっていることを検証
function StringLengthValidatorEvaluateIsValid(val) {
    var value = ValidatorGetValue(val.controltovalidate);
    if (value.length == 0)
        return true;

    return (value.length <= val.maximumvalue &&
			value.length >= val.minimumvalue);
}

// 日付文字列を検証
function DateDataTypeEvaluateIsValid(val) {
    var value = ValidatorGetValue(val.controltovalidate);
    if (ValidatorTrim(value).length == 0)
        return true;

    var rx = new RegExp(val.datatypeexpression);
    if (!rx.test(value))
        return false;

    value = FormatToYYYYMMDD(value);

    var day, month, year;

    year = value.substr(0, 4);
    month = value.substr(4, 2);
    day = value.substr(6, 2);

    // Javascriptは、0-11で表現
    month -= 1;

    // yearが0000の場合は無条件でNG
    if (year == "0000") {
        return false;
    }

    var date = new Date(year, month, day);
    if (typeof (date) == "object" && date.getFullYear() != year) {
        date.setFullYear(year);
    }
    if (typeof (date) == "object" && year == date.getFullYear() && month == date.getMonth() && day == date.getDate()) {
        return true;
    }
    else {
        return false;
    }
}

function CreateNewDate(value) {

    year = value.substr(0, 4);
    month = value.substr(4, 2);
    day = value.substr(6, 2);

    // Javascriptは、0-11で表現
    month -= 1;

    return new Date(year, month, day);
}

function FormatToYYYYMMDD(value) {
    // 全置換：すべての文字列 org を dest に置き換える   
    String.prototype.replaceAll = function (org, dest) {
        return this.split(org).join(dest);
    }

    value = value.replaceAll('.', '');
    value = value.replaceAll('/', '');
    value = value.replaceAll('-', '');

    return value;
}