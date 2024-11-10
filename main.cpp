#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QTranslator>
#include <QQmlContext>
#include <QtEnvironmentVariables>
#include <QtGlobal>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    QString platformName = app.platformName();
    if (platformName != "android" && platformName != "ios") {
        // Load the translators
        QStringList languages = {"en", "ja", "vi"};
        for (const QString &language : languages) {
            std::unique_ptr<QTranslator> translator(new QTranslator);
            if (translator->load(QLocale(language), QString("qml"), QLatin1String("_"), QLatin1String(":/qt/qml/QReminder/i18n/"))) {
                app.installTranslator(translator.get());
            } else {
                qWarning() << "Failed to load translation: " << language;
            }
        }

        // Set relative music path to QML
        engine.rootContext()->setContextProperty("applicationDirPath", QGuiApplication::applicationDirPath());
    }
    engine.load(":/qt/qml/QReminder/main.qml"); // Qt6.5+ uses :/qt/qml/ instead of :/
    if (engine.rootObjects().isEmpty())
        return -1;
    return app.exec();
}
