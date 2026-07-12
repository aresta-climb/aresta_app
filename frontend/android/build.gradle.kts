import com.android.build.gradle.BaseExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

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
    afterEvaluate {
        val extension = extensions.findByType<BaseExtension>()
        if (extension != null && extension.namespace.isNullOrBlank()) {
            val fallbackNamespace = "com.pkmnapps." + project.name.replace("-", "_")
            extension.namespace = project.group.toString().ifBlank { fallbackNamespace }
        }
    }
    

    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
