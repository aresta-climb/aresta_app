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
    val fixNamespace = Action<Project> {
        val extension = extensions.findByType<BaseExtension>()
        if (extension != null && extension.namespace.isNullOrBlank()) {
            val fallbackNamespace = "com.pkmnapps." + project.name.replace("-", "_")
            extension.namespace = project.group.toString().ifBlank { fallbackNamespace }
        }
    }
    if (project.state.executed) {
        fixNamespace.execute(project)
    } else {
        afterEvaluate(fixNamespace)
    }
    

    project.evaluationDependsOn(":app")

    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
    }
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
