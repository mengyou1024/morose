#include "common.h"
#include "../morose_config.h"

void Morose::logMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg) {
    static QMutex mutex;
    static int    maxCatelogyLen = 12;
    int           categoryLen    = QString(context.category).length();
    static int    maxMsgLen      = 0;
    int           msgLen         = msg.length();
    if (categoryLen > maxCatelogyLen) {
        maxCatelogyLen = categoryLen;
    }
    if (msgLen > maxMsgLen) {
        maxMsgLen = msgLen;
    }
    QString logLevel;
    auto    temp        = QString("[%1]").arg(QString(context.category)).toStdString();
    QString logCategory = QString::asprintf("%-*s", maxCatelogyLen + 2, temp.c_str());

#ifdef QT_DEBUG
    switch (type) {
        case QtDebugMsg: {
            logLevel = QString("\033[49m[D]\033[0m");
            break;
        }
        case QtWarningMsg: {
            logLevel = QString("\033[43m[W]\033[0m");
            break;
        }
        case QtCriticalMsg: {
            logLevel = QString("\033[45m[E]\033[0m");
            break;
        }
        case QtFatalMsg: {
            logLevel = QString("\033[41m[F]\033[0m");
            break;
        }
        case QtInfoMsg: {
            logLevel = QString("\033[42m[I]\033[0m");
            break;
        }
    }
#else
    switch (type) {
        case QtDebugMsg: {
            logLevel = QString("[D]");
            break;
        }
        case QtWarningMsg: {
            logLevel = QString("[W]");
            break;
        }
        case QtCriticalMsg: {
            logLevel = QString("[E]");
            break;
        }
        case QtFatalMsg: {
            logLevel = QString("[F]");
            break;
        }
        case QtInfoMsg: {
            logLevel = QString("[I]");
            break;
        }
    }
#endif

    QString logTimeInfo = QDateTime::currentDateTime().toString("[yyyy-MM-dd hh:mm:ss.zzz]");
    QString message     = QString("%1 %2 %3 %4")
                          .arg(logTimeInfo, logLevel, logCategory, QString("%1%2").arg(msg, QString(maxMsgLen - msgLen, ' ')));
    message.replace("\n", QString("\n") + QString(33 + maxCatelogyLen, ' '));

#if defined(QT_DEBUG)
    mutex.lock();
    printf("%s\n", message.toLocal8Bit().toStdString().c_str());
    fflush(stdout);
    mutex.unlock();
#else
    QFile file("./log/log.txt");
    mutex.lock();
    if (file.size() > 1024 * 1024 * 4) {
        QFile::copy("log/log.txt", "log/log0.txt");
        file.resize(0);
    }
    file.open(QFile::WriteOnly | QIODevice::Append);
    QTextStream text_stream(&file);
    if (type == QtCriticalMsg || type == QtFatalMsg) {
        QFile _file("./log/error.txt");
        _file.open(QFile::WriteOnly | QIODevice::Append);
        QTextStream _text_stream(&file);
        _text_stream << message << "\n";
        _file.flush();
        _file.close();
    }
    text_stream << message << "\n";
    file.flush();
    file.close();
    mutex.unlock();
#endif
}

void Morose::registerVariable(QQmlContext *context) {
    context->setContextProperty("MOROSE_APP_VERSION", APP_VERSION);
    context->setContextProperty("MOROSE_GIT_REPOSITORY", GIT_REPOSITORY);
    context->setContextProperty("MOROSE_GIT_USER_NAME", GIT_USER_NAME);
    context->setContextProperty("MOROSE_GIT_USER_EMAIL", GIT_USER_EMAIL);
}

QJsonObject &Morose::getGlobalEnvironment() {
    static QJsonObject obj;
    return obj;
}

QJsonObject &Morose::loadGlobalEnvironment() {
    QFile file("Config.json");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        if (doc.isObject()) {
            getGlobalEnvironment() = doc.object();
        }
        file.close();
    }
    qDebug() << getGlobalEnvironment();
    return getGlobalEnvironment();
}
