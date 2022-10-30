const { info } = require('console');
const dialogReq = require('.');

const dialog = new dialogReq.Dialog();

dialog.setDefaultOptions({
    height: 300,
    width: 400,
    icon: "info",
    okLabel: "Ados",
    cancelLabel: "Utzi"
});

const question = () => dialog.question('title', 'galdera').then(isOk => {
    (isOk) ? console.log('BAI') : console.log('EZ');
    selectFile();
});

const selectFile = () => dialog.selectFile('hartzu hutsuneekin', true, true).then(resp => {
    console.log('selectFile.response: ' + resp.v);
    entry();
});

const entry = () => dialog.entry('hartzu hutsuneekin', "nahi duzuna idatzi", 'placeholder').then(resp => {
    console.log('entry.response: ' + resp.v);
    progress();
});

const progress = () => {
    let p = dialog.progress('ari naiz', 'zenbat?');
    let val = 0;
    let intervalId = setInterval(() => {
        val += 10;
        p.progress(val);
        if (val == 100) {
            clearInterval(intervalId);
            password();
        }

    }, 500);
}

const password = () => dialog.password('sartu pasahitza', 'izena eta pasahitza', true).then(resp => {
    if (resp.v != undefined)
        console.log('password.response: ' + resp.v.username + '/' + resp.v.password);
    color();
});

const color = () => dialog.color('aukeratu kolorea').then(resp => {
    const c = resp.v;
    console.log('color.response: ');
    console.log(c);
    calendar();
});

const calendar = () => dialog.calendar('aukeratu eguna', 'testua', 1985, 8, 21, '%Y/%m/%d').then(resp => {
    if (resp.v != undefined)
        console.log('calendar.response: ' + resp.v);
    list();
});

const list = () => dialog.list('aukeratu eguna', 'testua', 'goiburua', ['bat', 'bi', 'hiru'], true).then(resp => {
    console.log('list.response: ' + resp.v);
    custom();
});

const custom = () => dialog.custom('C:/josu/git/ideckia/clialogs/custom_dialog.json').then(resp => {
    if (resp.v != undefined)
        resp.v.forEach(e => {
            console.log('value ->' + e.id + '=' + e.value);
        });
    dialog.notify('Test', 'akabo proba');
}).catch(e => console.log("ERROREA: " + e));

// dialog.info('title', 'info');
question();