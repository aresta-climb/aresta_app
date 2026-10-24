import com.android.build.gradle.BaseExtension

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
}

subprojects {
    // Fix for older Flutter plugins breaking in AGP 8.0+ due to missing namespace
    plugins.withId("com.android.library") {
        val extension = extensions.findByType<BaseExtension>()
        if (extension != null) {
            if (extension.namespace.isNullOrBlank()) {
                val fallbackNamespace = "com.pkmnapps." + project.name.replace("-", "_")
                extension.namespace = project.group.toString().ifBlank { fallbackNamespace }
            }
        }
    }
    

    project.evaluationDependsOn(":app")

    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
