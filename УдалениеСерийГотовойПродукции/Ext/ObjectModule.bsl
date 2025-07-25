﻿
#Область ОписаниеПеременных

Перем ДатаНачала;
Перем ДатаОкончания;
Перем Разделитель;
Перем Признак;

#КонецОбласти

#Область ПрограммныйИнтерфейс

// Функция возвращает структуру с регистрационными данными внешней обработки, включая наименование, версию, информацию и команды.
// 
// Возвращаемое значение:
// Структура - Регистрационные данные внешней обработки
//
Функция СведенияОВнешнейОбработке() Экспорт
	
	РегистрационныеДанные = Новый Структура;
	РегистрационныеДанные.Вставить("Наименование", "Удаление серий готовой продукции");
	РегистрационныеДанные.Вставить("ФормированиеФоновогоЗадания", Истина);
	РегистрационныеДанные.Вставить("ВерсияБСП", "1.2.1.4");
	РегистрационныеДанные.Вставить("Версия", "1.0");
	РегистрационныеДанные.Вставить("Информация", "Удаление серий готовой продукции");
	
	Команды = Новый ТаблицаЗначений;
	Команды.Колонки.Добавить("Идентификатор");
	Команды.Колонки.Добавить("Представление");
	
	СтрокаКоманды = Команды.Добавить();
	СтрокаКоманды.Идентификатор = Новый УникальныйИдентификатор;
	СтрокаКоманды.Представление = "Удаление серий готовой продукции";
	
	РегистрационныеДанные.Вставить("Команды", Команды);
	
	Возврат РегистрационныеДанные;
	
КонецФункции

// Выполняет команду, идентифицируемую уникальным идентификатором, с использованием предоставленных параметров обработки. В данном случае вызывает процедуру выполнения задания для выгрузки QR-кодов подлинности.
// 
// Параметры:
//  ИдентификаторКоманды - УникальныйИдентификатор - Идентификатор команды, которую необходимо выполнить.
//  ПараметрыОбработки   - Структура               - Параметры, используемые для обработки команды.
//
Процедура ВыполнитьКоманду(ИдентификаторКоманды,ПараметрыОбработки) Экспорт
	
	ВыполнитьЗадание();
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

// Процедура выполняет задание удалению серий из документов. Включает подготовку данных и перепроведение документов
//
Процедура ВыполнитьЗадание() Экспорт
	
	Если ДатаНачала = Дата(1, 1, 1) Тогда
		Возврат;
	КонецЕсли;
	
	Текст = СтрШаблон(НСтр("ru = 'Начало удаления партий ""%1"".'"), ТекущаяДатаСеанса());
	ОбщегоНазначения.СообщитьИнформациюПользователю(Текст);
	
	ДокументыДляОбработки = ДокументыДляОбработки();
	УдалитьСерииИПровести(ДокументыДляОбработки);
	
	Текст = СтрШаблон(НСтр("ru = 'Конец удаления партий ""%1"".'"), ТекущаяДатаСеанса());
	ОбщегоНазначения.СообщитьИнформациюПользователю(Текст);
	
	ОчиститьЗапись();
	
КонецПроцедуры

// Функция выполняет выборку документов
//
// Возвращаемое значение:
// Массив - документы
//
Функция ДокументыДляОбработки()
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	Номенклатура.Ссылка
	|ПОМЕСТИТЬ ВТНоменклатура
	|ИЗ
	|	Справочник.Номенклатура КАК Номенклатура
	|ГДЕ
	|	Номенклатура.Ссылка В ИЕРАРХИИ(&Номенклатура)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|ВЫБРАТЬ РАЗЛИЧНЫЕ
	|	ОтчетПроизводстваЗаСменуПродукция.Ссылка КАК Документ
	|ИЗ
	|	Документ.ОтчетПроизводстваЗаСмену.Продукция КАК ОтчетПроизводстваЗаСменуПродукция
	|ГДЕ
	|	ОтчетПроизводстваЗаСменуПродукция.Ссылка.Дата МЕЖДУ &НачПериод И &КонПериод
	|	И ОтчетПроизводстваЗаСменуПродукция.Номенклатура В
	|			(ВЫБРАТЬ
	|				ВТНоменклатура.Ссылка
	|			ИЗ
	|				ВТНоменклатура КАК ВТНоменклатура)
	|	И ОтчетПроизводстваЗаСменуПродукция.СерияНоменклатуры <> ЗНАЧЕНИЕ(Справочник.СерииНоменклатуры.ПустаяСсылка)
	|	И ОтчетПроизводстваЗаСменуПродукция.Ссылка.Проведен = ИСТИНА
	|
	|ОБЪЕДИНИТЬ
	|
	|ВЫБРАТЬ РАЗЛИЧНЫЕ
	|	РеализацияТоваровУслугТовары.Ссылка
	|ИЗ
	|	Документ.РеализацияТоваровУслуг.Товары КАК РеализацияТоваровУслугТовары
	|ГДЕ
	|	РеализацияТоваровУслугТовары.Ссылка.Дата МЕЖДУ &НачПериод И &КонПериод
	|	И РеализацияТоваровУслугТовары.Номенклатура В
	|			(ВЫБРАТЬ
	|				ВТНоменклатура.Ссылка
	|			ИЗ
	|				ВТНоменклатура КАК ВТНоменклатура)
	|	И РеализацияТоваровУслугТовары.СерияНоменклатуры <> ЗНАЧЕНИЕ(Справочник.СерииНоменклатуры.ПустаяСсылка)
	|	И РеализацияТоваровУслугТовары.Ссылка.Проведен = ИСТИНА
	|
	|ОБЪЕДИНИТЬ
	|
	|ВЫБРАТЬ РАЗЛИЧНЫЕ
	|	КорректировкаКачестваТоваровТовары.Ссылка
	|ИЗ
	|	Документ.КорректировкаКачестваТоваров.Товары КАК КорректировкаКачестваТоваровТовары
	|ГДЕ
	|	КорректировкаКачестваТоваровТовары.Ссылка.Дата МЕЖДУ &НачПериод И &КонПериод
	|	И КорректировкаКачестваТоваровТовары.Номенклатура В
	|			(ВЫБРАТЬ
	|				ВТНоменклатура.Ссылка
	|			ИЗ
	|				ВТНоменклатура КАК ВТНоменклатура)
	|	И КорректировкаКачестваТоваровТовары.СерияНоменклатуры <> ЗНАЧЕНИЕ(Справочник.СерииНоменклатуры.ПустаяСсылка)
	|	И КорректировкаКачестваТоваровТовары.Ссылка.Проведен = ИСТИНА
	|
	|ОБЪЕДИНИТЬ
	|
	|ВЫБРАТЬ РАЗЛИЧНЫЕ
	|	ПеремещениеТоваровТовары.Ссылка
	|ИЗ
	|	Документ.ПеремещениеТоваров.Товары КАК ПеремещениеТоваровТовары
	|ГДЕ
	|	ПеремещениеТоваровТовары.Ссылка.Дата МЕЖДУ &НачПериод И &КонПериод
	|	И ПеремещениеТоваровТовары.Номенклатура В
	|			(ВЫБРАТЬ
	|				ВТНоменклатура.Ссылка
	|			ИЗ
	|				ВТНоменклатура КАК ВТНоменклатура)
	|	И ПеремещениеТоваровТовары.СерияНоменклатуры <> ЗНАЧЕНИЕ(Справочник.СерииНоменклатуры.ПустаяСсылка)
	|	И ПеремещениеТоваровТовары.Ссылка.Проведен = ИСТИНА
	|
	|ОБЪЕДИНИТЬ
	|
	|ВЫБРАТЬ РАЗЛИЧНЫЕ
	|	ТребованиеНакладнаяМатериалы.Ссылка
	|ИЗ
	|	Документ.ТребованиеНакладная.Материалы КАК ТребованиеНакладнаяМатериалы
	|ГДЕ
	|	ТребованиеНакладнаяМатериалы.Ссылка.Дата МЕЖДУ &НачПериод И &КонПериод
	|	И ТребованиеНакладнаяМатериалы.Номенклатура В
	|			(ВЫБРАТЬ
	|				ВТНоменклатура.Ссылка
	|			ИЗ
	|				ВТНоменклатура КАК ВТНоменклатура)
	|	И ТребованиеНакладнаяМатериалы.СерияНоменклатуры <> ЗНАЧЕНИЕ(Справочник.СерииНоменклатуры.ПустаяСсылка)
	|	И ТребованиеНакладнаяМатериалы.Ссылка.Проведен = ИСТИНА
	|
	|ОБЪЕДИНИТЬ
	|
	|ВЫБРАТЬ РАЗЛИЧНЫЕ
	|	КомплектацияНоменклатуры.Ссылка
	|ИЗ
	|	Документ.КомплектацияНоменклатуры КАК КомплектацияНоменклатуры
	|ГДЕ
	|	КомплектацияНоменклатуры.Ссылка.Дата МЕЖДУ &НачПериод И &КонПериод
	|	И КомплектацияНоменклатуры.Номенклатура В
	|			(ВЫБРАТЬ
	|				ВТНоменклатура.Ссылка
	|			ИЗ
	|				ВТНоменклатура КАК ВТНоменклатура)
	|	И КомплектацияНоменклатуры.СерияНоменклатуры <> ЗНАЧЕНИЕ(Справочник.СерииНоменклатуры.ПустаяСсылка)
	|	И КомплектацияНоменклатуры.Проведен = ИСТИНА";
	
	Запрос.УстановитьПараметр("НачПериод", ДатаНачала);
	Запрос.УстановитьПараметр("КонПериод", ДатаОкончания);
	
	ДанныеНоменклатурыДляОтбора = СтрРазделить(Константы.СибиарДанныеНоменклатурыДляОтбора.Получить(), Разделитель);
	Номенклатура = Новый Массив;
	Для Каждого Элемент Из ДанныеНоменклатурыДляОтбора Цикл
		Номенклатура.Добавить(Справочники.Номенклатура.НайтиПоКоду(Элемент));
	КонецЦикла;
	Запрос.УстановитьПараметр("Номенклатура", Номенклатура);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	Возврат РезультатЗапроса.Выгрузить().ВыгрузитьКолонку("Документ");
	
КонецФункции

// Удаляет серии из документов и проводит их
//
// Параметры:
// ДокументыДляОбработки  - Массив документов
//
Процедура УдалитьСерииИПровести(ДокументыДляОбработки)
	
	ТабличныеЧасти = ИменаТабличныхЧастей();
	
	Для Каждого Документ Из ДокументыДляОбработки Цикл
		
		ДокументОбъект = Документ.ПолучитьОбъект();
		
		Если ТипЗнч(ДокументОбъект) = Тип("ДокументОбъект.КомплектацияНоменклатуры") Тогда
			КомплектацияНоменклатуры(ДокументОбъект);
		ИначеЕсли ТипЗнч(ДокументОбъект) = Тип("ДокументОбъект.ОтчетПроизводстваЗаСмену") Тогда
			ОтчетПроизводстваЗаСмену(ДокументОбъект);
		Иначе
			ОстальныеДокументы(ДокументОбъект);
		КонецЕсли;
		
		Попытка
			ДокументОбъект.Записать(РежимЗаписиДокумента.Проведение);
			Текст = СтрШаблон(НСтр("ru = 'Серии удалены! Проведен документ ""%1"".'"), Документ);
			ОбщегоНазначения.СообщитьИнформациюПользователю(Текст);
		Исключение
			Текст = СтрШаблон(НСтр("ru = 'Не удалось провести документ ""%1"".' "), Документ);
			ОбщегоНазначения.СообщитьИнформациюПользователю(Текст + ОписаниеОшибки());
		КонецПопытки;
		
	КонецЦикла;
	
КонецПроцедуры

// Удаляет серию из документа
//
// Параметры:
// Документ  - ДокументСсылка.КомплектацияНоменклатуры
//
Функция КомплектацияНоменклатуры(Документ)
	
	Документ.СерияНоменклатуры = Справочники.СерииНоменклатуры.ПустаяСсылка();
	
КонецФункции

// Удаляет серии продукции из документа Отчет производства за смену
//
// Параметры:
// Документ  - ДокументСсылка.ОтчетПроизводстваЗаСмену
//
Функция ОтчетПроизводстваЗаСмену(Документ)
	
	Для Каждого Строка Из Документ.Продукция Цикл
		Строка.СерияНоменклатуры = Справочники.СерииНоменклатуры.ПустаяСсылка();
	КонецЦикла;
	
	Для Каждого Строка Из Документ.РаспределениеМатериалов Цикл
		Строка.СерияПродукции = Справочники.СерииНоменклатуры.ПустаяСсылка();
	КонецЦикла;
	
КонецФункции

// Удаляет серии продукции из документа
//
// Параметры:
// Документ  - ДокументСсылка
//
Функция ОстальныеДокументы(Документ)
	
	ИменаТабличныхЧастей = ИменаТабличныхЧастей();
	ИмяТЧ = ИменаТабличныхЧастей.Получить(ТипЗнч(Документ));
	
	Для Каждого Строка Из Документ[ИмяТЧ] Цикл
		Строка.СерияНоменклатуры = Справочники.СерииНоменклатуры.ПустаяСсылка();
	КонецЦикла;
	
КонецФункции

// Устанавливает имена табличных частей соответствующий типу объета
//
// Возвращаемое значение:
// Соответствие   - имена табличных частей соответствующий типу объета
//
Функция ИменаТабличныхЧастей()
	
	ИменаТабличныхЧастей = Новый Соответствие;
	ИменаТабличныхЧастей.Вставить(Тип("ДокументОбъект.РеализацияТоваровУслуг"), "Товары");
	ИменаТабличныхЧастей.Вставить(Тип("ДокументОбъект.КорректировкаКачестваТоваров"), "Товары");
	ИменаТабличныхЧастей.Вставить(Тип("ДокументОбъект.ПеремещениеТоваров"), "Товары");
	ИменаТабличныхЧастей.Вставить(Тип("ДокументОбъект.ТребованиеНакладная"), "Материалы");
	
	Возврат ИменаТабличныхЧастей;
	
КонецФункции

// Удаляет запись из Регистра сведений сибиарДанныеДляРегламентнойРаботы, период обрабтки документов
// для удаления серий из них
//
Процедура ОчиститьЗапись()
	
	Запись = РегистрыСведений.сибиарДанныеДляРегламентнойРаботы.СоздатьМенеджерЗаписи();
	Запись.Признак = Признак;
	Запись.ДатаНачала = ДатаНачала;
	Запись.ДатаОкончания = ДатаОкончания;
	Запись.Удалить();
	
КонецПроцедуры

#КонецОбласти

#Область Инициализация

ДатаНачала = Дата(1, 1, 1);
ДатаОкончания = Дата(1, 1, 1);
Признак = "УдалениеСерий";
НаборЗаписей = РегистрыСведений.сибиарДанныеДляРегламентнойРаботы.СоздатьНаборЗаписей();
НаборЗаписей.Отбор.Признак.Установить(Признак);
НаборЗаписей.Прочитать();
Для Каждого Запись Из НаборЗаписей Цикл
	ДатаНачала = Запись.ДатаНачала;
	ДатаОкончания = Запись.ДатаОкончания;
КонецЦикла;
Разделитель = ";";

#КонецОбласти