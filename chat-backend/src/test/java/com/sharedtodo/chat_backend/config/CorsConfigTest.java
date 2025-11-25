package com.sharedtodo.chat_backend.config;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class CorsConfigTest {

    @Autowired
    private ApplicationContext context;

    @Test
    void corsConfigurerBeanExists() {
        WebMvcConfigurer bean = (WebMvcConfigurer) context.getBean("corsConfigurer");
        assertThat(bean).isNotNull();
    }
}
