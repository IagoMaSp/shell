#include "common.hpp"

#include <qstandardpaths.h>

namespace caelestia::state {

using Qt::StringLiterals::operator""_s;

Q_LOGGING_CATEGORY(lcState, "caelestia.state", QtInfoMsg)

QString stateDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericStateLocation) + u"/paleshell"_s;
}

QString monitorStateDir() {
    return stateDir() + u"/monitors"_s;
}

QString runtimeDir() {
    return QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation) + u"/paleshell"_s;
}

QString monitorRuntimeDir() {
    return runtimeDir() + u"/monitors"_s;
}

} // namespace caelestia::state
