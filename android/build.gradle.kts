allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    val configureAndroid = {
        val android = extensions.findByName("android")
        if (android != null) {
            val methods = listOf("compileSdkVersion", "setCompileSdkVersion", "setCompileSdk")
            var done = false
            for (methodName in methods) {
                if (done) break
                try {
                    val method = android.javaClass.getMethod(methodName, Int::class.javaPrimitiveType)
                    method.invoke(android, 36)
                    done = true
                } catch (e: Exception) {
                    try {
                        val method = android.javaClass.getMethod(methodName, java.lang.Integer::class.java)
                        method.invoke(android, 36)
                        done = true
                    } catch (e2: Exception) {
                        // Try next method
                    }
                }
            }
        }
    }

    try {
        afterEvaluate {
            configureAndroid()
        }
    } catch (e: Exception) {
        configureAndroid()
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
