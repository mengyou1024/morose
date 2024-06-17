#pragma once

#include <QtCore>

class QmlTranslator : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString language READ language WRITE setTranslation NOTIFY languageChanged)

public:
    Q_INVOKABLE void    setTranslation(QString language);
    Q_INVOKABLE QString language() const;
    Q_INVOKABLE QList<QString> languageList() const;
    Q_INVOKABLE int            index() const;
    static QmlTranslator*      Instance();

signals:
    void languageChanged();

private:
    QTranslator                                       m_translator;
    QString                                           m_language    = {};
    inline static const QMap<QString, QList<QString>> m_languageMap = {
        {"Chinese", {"", "qt_zh_CN"}               },
        {"English", {"UnionOffline_en.qm", "qt_en"}},
    };
    QmlTranslator(QObject* parent = nullptr);
    Q_DISABLE_COPY_MOVE(QmlTranslator)
};
