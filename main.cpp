#include "common/common.h"
#include "morose_config.h"
#include <QApplication>
#include <QDebug>
#include <QDir>
#include <QGuiApplication>
#include <QPluginLoader>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <format>

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/img/morose.ico"));

    // 注册日志处理回调函数
    qInstallMessageHandler(Morose::logMessageHandler);

    // 高DPI适配策略
    QApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
    // 设置QMl渲染引擎使用OPENGL
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

    // 设置日志过滤规则
    QSettings logSetting("log/setting.ini", QSettings::IniFormat);
    logSetting.beginGroup("Rules");
    auto filter = logSetting.value("filterRules");
    if (filter.isNull()) {
        logSetting.setValue("filterRules", "");
        filter = logSetting.value("filterRules");
    }
    QLoggingCategory::setFilterRules(filter.toString());
    logSetting.endGroup();
    logSetting.sync();

    // 加载QML、注册环境变量
    const QUrl            url("qrc:/qml/main.qml");
    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    Morose::registerVariable(engine.rootContext());
    qDebug() << QString(100, '-').toStdString().c_str();
    Morose::loadGlobalEnvironment();
    qInfo() << std::format("{:-^80}", "application start, version: " APP_VERSION).c_str();
    engine.load(url);
    return app.exec();
}
