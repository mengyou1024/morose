#pragma once

#include <QJsonDocument>
#include <QJsonObject>
#include <QQmlContext>
#include <QtCore>

namespace Morose {
    void logMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg);
    void registerVariable(QQmlContext *context);
    void pluginsLoadTest(void);

    QJsonObject &loadGlobalEnvironment();
    QJsonObject &getGlobalEnvironment();
} // namespace Morose
