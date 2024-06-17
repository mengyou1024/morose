#include "qmltranslator.h"
#include <QLoggingCategory>

static Q_LOGGING_CATEGORY(TAG, "translator");

QmlTranslator::QmlTranslator(QObject* parent) :
QObject(parent) {
    QSettings languageSetting("setting.ini", QSettings::IniFormat);
    languageSetting.beginGroup("Languages");
    auto cur_lang = languageSetting.value("CurrentLanguage");
    if (cur_lang.isNull()) {
        QLocale locale;
        if (locale.language() == QLocale::Chinese) {
            cur_lang = m_languageMap.constBegin().key();
            languageSetting.setValue("CurrentLanguage", cur_lang);
        } else {
            cur_lang = qAsConst(m_languageMap).keys()[2];
            languageSetting.setValue("CurrentLanguage", cur_lang);
        }
    }
    qApp->removeTranslator(&m_translator);
    for (auto& it : m_languageMap[cur_lang.toString()]) {
        auto load_ret = m_translator.load(it, "translations");
        qInfo(TAG) << "load traslation file: " << it << ", return:" << load_ret;
    }
    qApp->installTranslator(&m_translator);
    languageSetting.endGroup();
    languageSetting.sync();
    m_language = cur_lang.toString();
}

void QmlTranslator::setTranslation(QString language) {
    QSettings languageSetting("setting.ini", QSettings::IniFormat);
    languageSetting.beginGroup("Languages");
    auto cur_lang = languageSetting.value("CurrentLanguage");
    if (cur_lang.toString() != language) {
        qApp->removeTranslator(&m_translator);
        for (auto& it : m_languageMap[language]) {
            auto load_ret = m_translator.load(it, "translations");
            qInfo(TAG) << "load traslation file: " << it << ", return:" << load_ret;
        }
        qApp->installTranslator(&m_translator);
        languageSetting.setValue("CurrentLanguage", language);
        emit languageChanged();
    }
    languageSetting.endGroup();
    languageSetting.sync();
}

QString QmlTranslator::language() const {
    return m_language;
}

QList<QString> QmlTranslator::languageList() const {
    return m_languageMap.keys();
}

int QmlTranslator::index() const {
    int i = 0;
    for (auto it = m_languageMap.constBegin(); it != m_languageMap.constEnd(); it++) {
        if (it.key() == m_language) {
            return i;
        }
        i++;
    }
    return -1;
}

QmlTranslator* QmlTranslator::Instance() {
    static QmlTranslator inst;
    return &inst;
}
