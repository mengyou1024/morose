#include "common/common.h"
#include "morose_config.h"
#include <QApplication>
#include <QDebug>
#include <QDir>
#include <QGuiApplication>
#include <QPluginLoader>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <SingleApplication.h>

int main(int argc, char* argv[]) {
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    SingleApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/img/morose.ico"));

    QDir logDir;
    if (!logDir.exists("log")) {
        logDir.mkdir("log");
    }

    // 注册日志处理回调函数
    qInstallMessageHandler(Morose::logMessageHandler);
    // 高DPI适配策略
    QApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
    // 设置QMl渲染引擎使用OPENGL
    QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);
    // 设置日志过滤规则
    QSettings logSetting("setting.ini", QSettings::IniFormat);
    logSetting.beginGroup("Rules");
    auto filter = logSetting.value("filterRules");
    if (filter.isNull()) {
#if defined(QT_DEBUG)
        logSetting.setValue("filterRules", "");
#else
        logSetting.setValue("filterRules", "*.debug=false");
#endif
        filter = logSetting.value("filterRules");
    }
    QLoggingCategory::setFilterRules(filter.toString());
    logSetting.endGroup();
    logSetting.sync();

    qInfo() << std::string(80, '-').c_str();
    qInfo() << "application start, version: " APP_VERSION;
    qInfo() << "app start param:";
    for (auto i = 0; i < argc; i++) {
        qInfo() << argv[i];
    }
    qInfo() << std::string(80, '-').c_str();

    // 加载QML、注册环境变量
    const QUrl            url("qrc:/qml/main.qml");
    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, &app,
        [url](QObject* obj, const QUrl& objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    Morose::registerVariable(engine.rootContext());
    Morose::loadGlobalEnvironment();

    engine.load(url);
    QObject::connect(&app, &QApplication::aboutToQuit, &app, []() {
        qInfo() << "application quit";
    });

    auto rootObjs   = engine.rootObjects();
    auto mainWindow = qobject_cast<QQuickWindow*>(rootObjs.first());
    QObject::connect(&app, &SingleApplication::instanceStarted, mainWindow, [mainWindow]() {
        mainWindow->setFlag(Qt::WindowStaysOnTopHint, true);
        if (mainWindow->windowState() == Qt::WindowMaximized) {
            mainWindow->resize(mainWindow->minimumSize());
            mainWindow->setX((QGuiApplication::primaryScreen()->geometry().width() - mainWindow->minimumSize().width()) / 2);
            mainWindow->setY((QGuiApplication::primaryScreen()->geometry().height() - mainWindow->minimumSize().height()) / 2);
        }
        mainWindow->showNormal();
        mainWindow->setFlag(Qt::WindowStaysOnTopHint, false);
        mainWindow->requestActivate();
        mainWindow->raise();
    });
    return app.exec();
}
