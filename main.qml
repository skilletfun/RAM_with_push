import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.12


Window {
    width: 900
    height: 600
    minimumHeight: 600
    minimumWidth: 900
    visible: true
    title: qsTr("RAM с выталкиванием")

    Row {
        id: title_row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 50
        anchors.leftMargin: 50
        anchors.topMargin: 25
        spacing: 25

        Text {
            font.pointSize: 14
            text: 'Стратегия:'
            anchors.verticalCenter: parent.verticalCenter
        }

        ComboBox {
            id: ram_mode
            width: parent.width/3
            height: 50
            font.pointSize: 12
            anchors.verticalCenter: parent.verticalCenter

            model: ['Первый подходящий', "Самый подходящий", "Самый неподходящий", "Случайный (из подходящих)"]
        }

        Text {
            font.pointSize: 14
            text: 'Объем памяти:'
            anchors.verticalCenter: parent.verticalCenter
        }

        ComboBox {
            id: ram_size
            width: 100
            height: 50
            anchors.verticalCenter: parent.verticalCenter
            font.pointSize: 12

            model: ['512', "1024", "2048", "4096", '8192']

            onCurrentTextChanged: {
                view_model.clear();
                view_model.append({ pos: -1, size: Number(currentText) });
                add_process_btn.counter = 1;
            }
        }

        Rectangle { color: 'transparent'; height: 1; width: 25 }

        Button {
            id: reload
            height: 50
            width: height
            background: Rectangle {color: 'transparent'}

            onReleased: {
                add_process_btn.counter = 1;
                view_model.clear();
                view_model.append({ pos: -1, size: Number(ram_size.currentText) });
            }

            Image {
                anchors.fill: parent
                source: "reset.png"
                mipmap: true
            }
        }
    }

    Row {
        id: settings
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 50
        anchors.leftMargin: 50
        anchors.bottomMargin: 25
        spacing: 50

        Button {
            id: add_process_btn

            property int counter: 1

            enabled: process_size.text != '' ? true : false
            width: 200
            height: 50
            font.pointSize: 12
            text: 'Создать процесс:'
            anchors.verticalCenter: parent.verticalCenter
            onReleased: { add_process(process_size.text); }
        }

        TextField {
            id: process_size
            placeholderText: '128'
            width: 100
            height: 50
            anchors.verticalCenter: parent.verticalCenter
            font.pointSize: 12
            horizontalAlignment: TextInput.AlignHCenter
            validator: RegExpValidator { regExp: /[0-9]+/}
            onAccepted: { focus = false; }
        }

        Button {
            id: remove_process_btn
            width: 200
            height: 50
            anchors.verticalCenter: parent.verticalCenter
            font.pointSize: 12
            text: 'Удалить процесс:'
            onReleased: { remove_process(process_number.text); }
        }

        TextField {
            id: process_number
            placeholderText: 'Номер'
            width: 100
            height: 50
            anchors.verticalCenter: parent.verticalCenter
            font.pointSize: 12
            horizontalAlignment: TextInput.AlignHCenter
            validator: RegExpValidator { regExp: /[0-9]+/}
            onAccepted: { focus = false; }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: title_row.bottom
        anchors.bottom: settings.top
        anchors.left: parent.left
        anchors.margins: 25
        border.width: 1


        ListView {
            id: main_view
            clip: true
            anchors.fill: parent
            anchors.margins: 1
            interactive: false
            model: view_model

            add: Transition {
                PropertyAnimation { property: 'x'; from: -50; duration: 200 }
//                PropertyAnimation { property: 'color'; from: "#ffcc53"; duration: 200 }
            }

            delegate: Rectangle {
                width: main_view.width
                height: main_view.height/Number(ram_size.currentText)*Number(size)
                border.width: 1
                border.color: 'grey'
                color: pos >= 0 ? '#8effd2' : '#ceffd2'

                Text {
                    text: (pos >= 0 ? 'Процесс: ' + String(pos) +',  ' : 'Свободно:  ') + String(size) + ' Мб'
                    anchors.centerIn: parent
                    font.pointSize: 14
                }
            }
        }
    }

    ListModel {
        id: view_model

        ListElement {
            pos: -1
            size: 512
        }
    }

    function add_process(size)
    {
        size = Number(size);
        var flag = false;
        for (var i = 0; i < view_model.count; i++)
        {
            if (view_model.get(i).pos < 0 && view_model.get(i).size >= size)
            {
                view_model.insert(i, {pos: Number(add_process_btn.counter), size: size}); // Добавляем процесс

                view_model.setProperty(i+1, 'size', view_model.get(i+1).size - size); // Уменьшаем свободное место
                if (view_model.get(i+1).size === 0) view_model.remove(i+1); // Если свободное место - 0, то удаляем

                add_process_btn.counter += 1;

                flag = true;
                break;
            }
        }

        if (!flag)
        {
            // Если требование процесса больше всей памяти - просто очищаем
            if (size > Number(ram_size.currentText))
            {
                view_model.clear();
                view_model.append({pos: -1, size: Number(ram_size.currentText)});
            }
            else
            {
                if (ram_mode.currentIndex == 0) first_compare(size);
                else if (ram_mode.currentIndex == 1) most_compare(size);
                else if (ram_mode.currentIndex == 2) most_non_compare(size);
                else if (ram_mode.currentIndex == 3) random_compare(size);
                add_process_btn.counter += 1;
            }
        }
    }

    function remove_process(pos)
    {
        for (var i = 0; i < view_model.count; i++)
        {
            if (view_model.get(i).pos === Number(pos))
            {
                view_model.setProperty(i, 'pos', -1);
                break;
            }
        }
        // Проверить, есть ли подряд идущие блоки с пустой памятью и объединить их, если есть
        var flag = true;
        while (flag)
        {
            flag = false;
            i = 0;
            for (; i < view_model.count-1; i++)
            {
                if (view_model.get(i).pos === -1 && view_model.get(i+1).pos === -1)
                {
                    view_model.setProperty(i, 'size', view_model.get(i).size + view_model.get(i+1).size);
                    view_model.remove(i+1);
                    flag = true;
                    break;
                }
            }
        }
    }

    // Первый подходящий
    function first_compare(size)
    {
//        console.log('First compare');
        var current_index = -1;
        var total_process_for_remove = 0;
        var flag = true;

        // Ищем, что нужно очистить
        while (flag)
        {
            total_process_for_remove++;

            for (var i = 0; i < view_model.count + 1 - total_process_for_remove; i++)
            {
                var total_ram_size = 0
                for (var j = i; j < i+total_process_for_remove; j++)
                {
                    total_ram_size += view_model.get(j).size;
                }

                if (size <= total_ram_size)
                {
                    flag = false;
                    current_index = i;
                    break;
                }
            }
        }

        add_process_with_replace(current_index, total_process_for_remove, size);
    }

    // Самый подходящий
    function most_compare(size)
    {
//        console.log('Most compare');
        var current_index = -1;
        var total_process_for_remove = 0;
        var flag = true;
        var current_value = 9999;

        // Ищем, что нужно очистить
        while (flag)
        {
            total_process_for_remove++;

            for (var i = 0; i < view_model.count + 1 - total_process_for_remove; i++)
            {
                var total_ram_size = 0
                for (var j = i; j < i+total_process_for_remove; j++)
                {
                    total_ram_size += view_model.get(j).size;
                }

                if (size <= total_ram_size && total_ram_size < current_value)
                {
                    flag = false;
                    current_index = i;
                    current_value = total_ram_size;
                }
            }
        }

        add_process_with_replace(current_index, total_process_for_remove, size);
    }

    // Самый неподходящий
    function most_non_compare(size)
    {
//        console.log('Most non-compare');
        var current_index = -1;
        var total_process_for_remove = 0;
        var flag = true;
        var current_value = 0;

        // Ищем, что нужно очистить
        while (flag)
        {
            total_process_for_remove++;

            for (var i = 0; i < view_model.count + 1 - total_process_for_remove; i++)
            {
                var total_ram_size = 0
                for (var j = i; j < i+total_process_for_remove; j++)
                {
                    total_ram_size += view_model.get(j).size;
                }

                if (size <= total_ram_size && total_ram_size > current_value)
                {
                    flag = false;
                    current_index = i;
                    current_value = total_ram_size;
                }
            }
        }

        add_process_with_replace(current_index, total_process_for_remove, size);
    }

    // Рандом
    function random_compare(size)
    {
//        console.log('Random');
        var total_process_for_remove = 0;
        var flag = true;
        var arr = [];

        // Ищем, что нужно очистить
        while (flag)
        {
            total_process_for_remove++;

            for (var i = 0; i < view_model.count + 1 - total_process_for_remove; i++)
            {
                var total_ram_size = 0
                for (var j = i; j < i+total_process_for_remove; j++)
                {
                    total_ram_size += view_model.get(j).size;
                }

                if (size <= total_ram_size)
                {
                    flag = false;
                    arr.push(i);
                }
            }
        }
        var current_index = arr[Math.floor(arr.length * Math.random())];

        // Добавляем процесс (сначала очищая память)
        add_process_with_replace(current_index, total_process_for_remove, size);
    }

    function add_process_with_replace(index, count, size)
    {
        // Добавляем процесс (сначала очищая память)
        var total_size = 0;
        for (var i = 0; i < count; i++)
        {
            total_size += view_model.get(index).size;
            view_model.remove(index);
        }
        view_model.insert(index, { pos: Number(add_process_btn.counter), size: size });
        if (size < total_size) view_model.insert(index+1, { pos: -1, size: total_size - size });
    }
}
