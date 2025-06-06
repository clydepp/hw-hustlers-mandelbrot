export const translations = {
  en: {
    title: "Mandelbrot Viewer",
    subtitle: "Hardware Hustlers, Mathematics Accelerator",
    theory: "Theory",
    usage: "Usage", 
    optimisations: "Optimisations",
    accessibility: "Accessibility",
    coordinates: "Coordinates",
    zoom: "Zoom",
    manualConfig: "Manual Config",
    theoryContent: `The Mandelbrot set is the set of complex numbers c for which the sequence defined by:

    z₀ = 0
    zₙ₊₁ = zₙ² + c

remains bounded (does not escape to infinity) as n increases.

To determine whether a point c is in the Mandelbrot set:
1. Start with z = 0.
2. Repeatedly apply the function z = z² + c.
3. If |z| ever becomes greater than 2, the point c is NOT in the set.
4. If |z| stays less than or equal to 2 after many iterations, c is LIKELY in the set.

In practice:
- Each pixel on the screen represents a complex number c.
- We iterate z = z² + c for each pixel.
- Points that escape are colored based on how quickly they escape.
- Points that don't escape (stay bounded) are colored black.

This creates the famous fractal: infinitely detailed, self-similar, and complex.

Terms:
- c: complex number (real + imaginary part)
- |z|: magnitude of the complex number z
- Escape radius: usually set to 2
- Iteration count: how many times to repeat z = z² + c (e.g., 100–1000 times)

The boundary of the Mandelbrot set marks the edge between stability and chaos.`,
    optimisationsContent: "To speedup the Mandelbrot calculation: use GPU acceleration, parallel processing, and optimized algorithms...",
    accessibilityContent: "Includes multiple language support, colorblind-friendly palettes, and keyboard navigation."
  },
  es: {
    title: "Visor de Mandelbrot",
    subtitle: "Acelerador de Matemáticas",
    theory: "Teoría",
    usage: "Uso",
    optimisations: "Optimizaciones", 
    accessibility: "Accesibilidad",
    coordinates: "Coordenadas",
    zoom: "Zoom",
    manualConfig: "Configuración Manual",
    theoryContent: `El conjunto de Mandelbrot es el conjunto de números complejos c para los cuales la secuencia definida por:

    z₀ = 0
    zₙ₊₁ = zₙ² + c

permanece acotada (no escapa al infinito) a medida que n aumenta.

Para determinar si un punto c está en el conjunto de Mandelbrot:
1. Comience con z = 0.
2. Aplique repetidamente la función z = z² + c.
3. Si |z| se vuelve mayor que 2, el punto c NO está en el conjunto.
4. Si |z| permanece menor o igual a 2 después de muchas iteraciones, c probablemente ESTÁ en el conjunto.`,
    optimisationsContent: "Para acelerar el cálculo de Mandelbrot: use aceleración GPU, procesamiento paralelo y algoritmos optimizados...",
    accessibilityContent: "Incluye soporte para múltiples idiomas, paletas amigables para daltónicos y navegación por teclado."
  },
  zh: {
    title: "曼德博集合查看器",
    subtitle: "硬件加速数学计算器",
    theory: "理论",
    usage: "使用方法",
    optimisations: "优化",
    accessibility: "无障碍访问", 
    coordinates: "坐标",
    zoom: "缩放",
    manualConfig: "手动配置",
    theoryContent: `曼德博集合是复数c的集合，其序列定义为：

    z₀ = 0
    zₙ₊₁ = zₙ² + c

当n增加时保持有界（不会逃逸到无穷大）。

要确定点c是否在曼德博集合中：
1. 从z = 0开始。
2. 重复应用函数z = z² + c。
3. 如果|z|变得大于2，则点c不在集合中。
4. 如果|z|在多次迭代后保持小于或等于2，则c可能在集合中。`,
    optimisationsContent: "加速曼德博计算：使用GPU加速、并行处理和优化算法...",
    accessibilityContent: "包括多语言支持、色盲友好调色板和键盘导航。"
  },
  ar: {
    title: "عارض مجموعة مانديلبروت",
    subtitle: "مسرّع الرياضيات والأجهزة",
    theory: "النظرية",
    usage: "الاستخدام",
    optimisations: "التحسينات",
    accessibility: "إمكانية الوصول",
    coordinates: "الإحداثيات", 
    zoom: "التكبير",
    manualConfig: "التكوين اليدوي",
    theoryContent: `مجموعة مانديلبروت هي مجموعة الأرقام المعقدة c التي يتم تعريف تسلسلها بواسطة:

    z₀ = 0
    zₙ₊₁ = zₙ² + c

تبقى محدودة (لا تهرب إلى اللانهاية) مع زيادة n.

لتحديد ما إذا كانت النقطة c في مجموعة مانديلبروت:
1. ابدأ بـ z = 0.
2. طبق الدالة z = z² + c بشكل متكرر.
3. إذا أصبح |z| أكبر من 2، فإن النقطة c ليست في المجموعة.
4. إذا بقي |z| أقل من أو يساوي 2 بعد تكرارات كثيرة، فمن المحتمل أن c في المجموعة.`,
    optimisationsContent: "لتسريع حساب مانديلبروت: استخدم تسريع وحدة معالجة الرسومات، والمعالجة المتوازية، والخوارزميات المحسنة...",
    accessibilityContent: "يتضمن دعم اللغات المتعددة، ولوحات الألوان الصديقة لعمى الألوان، والتنقل بلوحة المفاتيح."
  }
};